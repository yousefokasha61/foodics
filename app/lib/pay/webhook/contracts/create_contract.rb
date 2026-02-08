# frozen_string_literal: true

module Pay
  module Webhook
    module Contracts
      class CreateContract < ::Pay::Shared::Contract
        BANK_WHITE_LIST = %w[FOODICS ACME].freeze
        params do
          config.validate_keys = true

          required(:wallet_id).filled(Types::Coercible::Integer, gt?: 0)
          required(:bank).filled(Types::Coercible::String, included_in?: BANK_WHITE_LIST)
          required(:raw_payload).filled(Types::Coercible::String)
        end
      end
    end
  end
end
