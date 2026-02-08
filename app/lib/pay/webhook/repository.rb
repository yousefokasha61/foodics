# frozen_string_literal: true

module Pay
  module Webhook
    class Repository
      include Dry::Monads[:result]

      def initialize
        super
      end

      def create(params)
        webhook = ::Webhook.new(**params)

        if webhook.save(validate: false)
          Success(webhook)
        else
          Failure(::Api::Error.unprocessable_entity(message: "Failed to create webhook record"))
        end
      end
    end
  end
end
