# frozen_string_literal: true

module Api
  module V1
    class PaymentsController < BaseController
      # POST /api/v1/wallets/:wallet_id/payments
      def create
        head :ok
      end

      private

      def wallet_id
        params[:wallet_id]
      end
    end
  end
end
