# frozen_string_literal: true

module Api
  module V1
    module Pay
      class TransfersController < BaseController
        include Dry::Monads[:result]

        # POST /api/v1/pay/transfers/:wallet_id
        def create
          result = ::Pay::Payment::Service.new(wallet_id: wallet_id).create(transfer_params)

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

        def transfer_params
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
end
