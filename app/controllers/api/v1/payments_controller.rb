# frozen_string_literal: true

module Api
  module V1
    class PaymentsController < BaseController
      include Dry::Monads[:result]

      # POST /api/v1/wallets/:wallet_id/payments
      def create
        result = Pay::Payment::Service.new(wallet_id: wallet_id).create(payment_params)

        case result
        in Success(xml)
          render xml: xml, status: :created
        in Failure(::Api::Error => error)
          render json: error.to_h, status: error.http_status_code
        end
      end

      private

      def wallet_id
        params[:wallet_id]
      end

      def payment_params
        params.permit(
          :amount,
          :currency,
          :payment_type,
          :charge_details,
          notes: [],
          receiver: [ :bank_code, :account_number, :beneficiary_name ]
        ).to_h.deep_symbolize_keys
      end
    end
  end
end
