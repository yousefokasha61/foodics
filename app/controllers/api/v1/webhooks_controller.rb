# frozen_string_literal: true

module Api
  module V1
    class WebhooksController < BaseController
      include Dry::Monads[:result]

      # POST /api/v1/wallets/:wallet_id/webhooks?bank=foodics
      def create
        result = Pay::Webhook::Service.new(wallet_id: params[:wallet_id]).create(
          wallet_id: params[:wallet_id],
          bank: params[:bank],
          raw_payload: request.raw_post
        )

        case result
        in Success(webhook)
          render json: { id: webhook.id, status: webhook.status }, status: :created
        in Failure(::Api::Error => error)
          render json: error.to_h, status: error.http_status_code
        end
      end
    end
  end
end
