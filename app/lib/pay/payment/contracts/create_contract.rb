# frozen_string_literal: true

module Pay
  module Payment
    module Contracts
      class CreateContract < Dry::Validation::Contract
        include Dry::Monads[:result]

        params do
          required(:receiver).hash do
            required(:bank_code).filled(:string)
            required(:account_number).filled(:string)
            required(:beneficiary_name).filled(:string)
          end
          required(:amount).filled(:float, gt?: 0)
          optional(:currency).filled(:string)
          optional(:notes).array(:string)
          optional(:payment_type).filled(:integer)
          optional(:charge_details).filled(:string)
        end

        def call(input)
          result = super(input)

          if result.success?
            Success(result.to_h)
          else
            Failure(::Api::Error.unprocessable_entity(result.errors.to_h.to_json))
          end
        end
      end
    end
  end
end
