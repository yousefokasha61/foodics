# frozen_string_literal: true

module Pay
  module Parser
    class ParsedTransaction < Dry::Struct
      module Types
        include Dry.Types()
      end

      attribute :reference, Types::String
      attribute :amount_cents, Types::Integer
      attribute :transaction_date, Types::Date
      attribute :metadata, Types::Hash.default({}.freeze)
    end
  end
end
