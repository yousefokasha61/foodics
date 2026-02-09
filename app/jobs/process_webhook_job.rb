# frozen_string_literal: true

class ProcessWebhookJob < ApplicationJob
  include Dry::Monads[:result]

  queue_as :default

  def perform(webhook_id)
    result = ::Pay::Webhook::Service.new.process(webhook_id:)

    case result
    in Success(:already_processing)
      Rails.logger.info "Webhook #{webhook_id} is already being processed by another worker."
    in Success(webhook)
      Rails.logger.info "Successfully processed webhook #{webhook.id} with status #{webhook.status}."
    in Failure(::Api::Error => error)
      Rails.logger.error "Failed to process webhook #{webhook_id}: #{error.message}"
    end
  end
end
