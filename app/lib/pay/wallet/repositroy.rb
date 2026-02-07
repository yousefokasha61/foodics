# frozen_string_literal: true

module Pay
  module Wallet
    class Repository
      def initialize(client: Client.new)
        @client = client
      end
    end
  end
end
