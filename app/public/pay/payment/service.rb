# frozen_string_literal: true

module Pay
  module Payment
    class Service
      include Dry::Monads[:result]

      def initialize(wallet_id:)
        @wallet_id = wallet_id
      end

      def create(params)
        Contracts::CreateContract.new.call(params).bind do |validated_params|
          wallet_repository.find_one.bind do |wallet|
            payment_request = build_payment_request(wallet, validated_params)
            xml = XmlBuilder.new(payment_request).build
            Success(xml)
          end
        end
      end

      private

      attr_reader :wallet_id

      def build_payment_request(wallet, params)
        PaymentRequest.new(
          reference: SecureRandom.uuid,
          date: Time.current.strftime("%Y-%m-%d %H:%M:%S%z"),
          amount: params[:amount],
          currency: params[:currency] || "SAR",
          sender_account_number: wallet.account_number,
          receiver_bank_code: params[:receiver][:bank_code],
          receiver_account_number: params[:receiver][:account_number],
          beneficiary_name: params[:receiver][:beneficiary_name],
          notes: params[:notes] || [],
          payment_type: params[:payment_type] || 99,
          charge_details: params[:charge_details] || "SHA"
        )
      end

      def wallet_repository
        @wallet_repository ||= ::Pay::Wallet::Repository.new(wallet_id: wallet_id)
      end
    end
  end
end
