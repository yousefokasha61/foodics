# frozen_string_literal: true

module Pay
  module Webhook
    module Ingestion
      # Manages webhook ingestion state via Redis.
      # When disabled, webhooks are still received and stored,
      # but processing is paused until re-enabled.
      class Cache
        include Dry::Monads[:result, :try]

        REDIS_KEY = "pay:ingestion:enabled"

        def enabled?
          Try { REDIS.get(REDIS_KEY) }
            .to_result
            .fmap { |value| value.nil? || value == "true" }
        end

        def disabled?
          enabled?.fmap { |enabled| !enabled }
        end

        def enable!
          Try { REDIS.set(REDIS_KEY, "true") }
            .to_result
            .fmap { true }
        end

        def disable!
          Try { REDIS.set(REDIS_KEY, "false") }
            .to_result
            .fmap { true }
        end

        def status
          enabled?.fmap { |enabled| { enabled: enabled } }
        end
      end
    end
  end
end
