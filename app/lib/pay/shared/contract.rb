# frozen_string_literal: true

module Pay
  module Shared
    class Contract < Dry::Validation::Contract
      include ::Dry::Monads[:result]

      module Types
        include Dry.Types()
      end

      def call(args, context = {})
        result = super(args, context)
        return Success(result.to_h) if result.success?

        Failure(to_error(result.errors.to_h))
      end

      private

      def to_error(errors)
        error = {
          code: "BAD_REQUEST",
          message: "Bad input",
          details: to_details(errors:)
        }
        ::Api::Error.build(error)
      end

      def to_details(errors:, root: [])
        if errors.is_a?(Array)
          return {
            reason_code: "INVALID_PROPERTY",
            message: errors.join(","),
            source: root.join(".")
          }
        end
        errors.flat_map do |k, v|
          to_details(root: root.dup << k, errors: v)
        end
      end
    end
  end
end
