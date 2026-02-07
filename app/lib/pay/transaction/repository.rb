# frozen_string_literal: true

module Pay
  module Transaction
    class Repository
      def initialize(client: Client.new)
        @client = client
      end
    end
  end
end
