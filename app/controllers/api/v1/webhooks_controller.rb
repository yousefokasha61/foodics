# frozen_string_literal: true

module Api
  module V1
    class WebhooksController < BaseController
      # POST /api/v1/wallets/:wallet_id/webhooks?bank=foodics
      def create
        head :ok
      end

      private

      def wallet_id
        params[:wallet_id]
      end

      def bank
        params[:bank]
      end
    end
  end
end
