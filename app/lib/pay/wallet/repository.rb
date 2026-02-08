# frozen_string_literal: true

module Pay
  module Wallet
    class Repository
      include ::Dry::Monads[:result]

      def initialize(wallet_id:)
        @wallet_id = wallet_id
      end

      def find_one
        wallet = ::Wallet.find_by(id: wallet_id)
        if wallet.nil?
          return Failure(::Api::Error.build(construct_not_found_error))
        end
        Success(wallet)
      end

      private

      attr_reader :wallet_id

      def construct_not_found_error
        {
          code: "NOT_FOUND",
          message: "Wallet with id #{wallet_id} not found"
        }
      end
    end
  end
end
