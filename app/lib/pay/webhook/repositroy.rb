# frozen_string_literal: true

module Pay
  module Webhook
    class Repository
      def initialize(client: Client.new)
        @client = client
      end
    end
  end
end
