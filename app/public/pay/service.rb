# frozen_string_literal: true

module Pay
  class Service
    def initialize(client: Client.new)
      @client = client
    end
  end
end
