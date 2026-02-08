# frozen_string_literal: true

module Pay
  module Webhook
    class Service
      include Dry::Monads[:result]

      def initialize(wallet_id: nil)
        @wallet_id = wallet_id
      end

      def create(params)
        ::Pay::Webhook::Contracts::CreateContract.new.call(params).bind do |validated_params|
          wallet_repository.find_one.bind do |wallet|
            repository.create(validated_params.merge(wallet_id: wallet.id)).bind do |webhook|
              enqueue_processing(webhook)
            end
          end
        end
      end

      def process(webhook_id:)
        # Atomically claim the webhook - returns 0 if already claimed
        claimed = ::Webhook.where(id: webhook_id, status: "PENDING")
                           .update_all(status: "PROCESSING", updated_at: Time.current)

        return Success(:already_processing) if claimed.zero?

        ::Webhook.transaction do
          webhook = ::Webhook.find(webhook_id)
          parser = ::Pay::Parser::Factory.for(webhook.bank)
          result = parser.parse(webhook.raw_payload)

          if result.transactions.any?
            inserted_total = create_transactions(webhook, result.transactions)
            update_wallet_balance(webhook.wallet_id, inserted_total) if inserted_total.positive?
            webhook.mark_as_processed!(processing_errors: result.errors)
          else
            webhook.mark_as_failed!(processing_errors: result.errors)
          end

          Success(webhook)
        end
      rescue StandardError => e
        ::Webhook.where(id: webhook_id).update_all(status: "FAILED")
        Failure(::Api::Error.internal_server_error(e.message))
      end

      private

      attr_reader :wallet_id

      def enqueue_processing(webhook)
        job = ProcessWebhookJob.perform_later(webhook.id)

        if job.successfully_enqueued?
          Success(webhook)
        else
          Failure(::Api::Error.internal_server_error("Failed to enqueue webhook processing"))
        end
      end

      def create_transactions(webhook, parsed_transactions)
        transactions = parsed_transactions.map do |tx|
          {
            wallet_id: webhook.wallet_id,
            webhook_id: webhook.id,
            bank: webhook.bank,
            reference: tx.reference,
            amount_cents: tx.amount_cents,
            transaction_date: tx.transaction_date,
            metadata: tx.metadata,
            created_at: Time.current,
            updated_at: Time.current
          }
        end

        # Returns only actually inserted rows (skips duplicates)
        inserted = ::Transaction.insert_all(
          transactions,
          unique_by: [ :bank, :reference ],
          returning: %w[amount_cents]
        )

        # Sum only the inserted transaction amounts
        inserted.rows.sum { |row| row[0].to_i }
      end

      def update_wallet_balance(wallet_id, amount_cents)
        ::Wallet.where(id: wallet_id).update_all(
          "balance_cents = balance_cents + #{amount_cents.to_i}"
        )
      end

      def wallet_repository
        @wallet_repository ||= ::Pay::Wallet::Repository.new(wallet_id: wallet_id)
      end

      def repository
        @repository ||= ::Pay::Webhook::Repository.new
      end
    end
  end
end
