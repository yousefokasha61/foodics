# frozen_string_literal: true

module Pay
  module Parser
    class Result < Dry::Struct
      module Types
        include Dry.Types()
      end

      attribute :transactions, Types::Array.of(ParsedTransaction).default([].freeze)
      attribute :errors, Types::Array.default([].freeze)

      def success?
        errors.empty?
      end

      def partial_success?
        transactions.any? && errors.any?
      end

      def failure?
        transactions.empty? && errors.any?
      end
    end
  end
end
