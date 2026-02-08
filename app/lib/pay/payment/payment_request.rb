# frozen_string_literal: true

module Pay
  module Payment
    class PaymentRequest < Dry::Struct
      # Transfer info
      attribute :reference, Types::String
      attribute :date, Types::String
      attribute :amount, Types::Coercible::Float
      attribute :currency, Types::String.default("SAR")

      # Sender info
      attribute :sender_account_number, Types::String

      # Receiver info
      attribute :receiver_bank_code, Types::String
      attribute :receiver_account_number, Types::String
      attribute :beneficiary_name, Types::String

      # Optional fields with defaults
      attribute :notes, Types::Array.of(Types::String).default([].freeze)
      attribute :payment_type, Types::Coercible::Integer.default(99)
      attribute :charge_details, Types::String.default("SHA")

      def notes?
        notes.any?
      end

      def payment_type?
        payment_type != 99
      end

      def charge_details?
        charge_details != "SHA"
      end
    end
  end
end
