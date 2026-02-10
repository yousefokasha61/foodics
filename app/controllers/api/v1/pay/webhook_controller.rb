# frozen_string_literal: true

module Api
  module V1
    module Pay
      class WebhookController < BaseController
        include Dry::Monads[:result]

        # POST /api/v1/pay/webhook
        # Headers:
        #   X-Wallet-ID: wallet identifier
        #   X-Bank: bank identifier (FOODICS, ACME)
        def create
          result = ::Pay::Webhook::Service.new(wallet_id: wallet_id).create(
            wallet_id: wallet_id,
            bank: bank,
            raw_payload: request.raw_post
          )

          case result
          in Success(webhook)
            render json: { id: webhook.id, status: webhook.status }, status: :created
          in Failure(::Api::Error => error)
            render json: error.to_h, status: error.http_status_code
          end
        end

        private

        def wallet_id
          request.headers["X-Wallet-ID"]
        end

        def bank
          request.headers["X-Bank"]
        end
      end
    end
  end
end
