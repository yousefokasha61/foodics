# frozen_string_literal: true

module Api
  module V1
    module Admin
      class IngestionsController < BaseController
        include Dry::Monads[:result]

        # GET /api/v1/admin/ingestion
        def show
          result = ingestion_cache.status

          case result
          in Success(status)
            render json: status
          in Failure(error)
            render json: { error: error.message }, status: :service_unavailable
          end
        end

        # PATCH /api/v1/admin/ingestion
        # Body: { "enabled": true } or { "enabled": false }
        def update
          enabling = params[:enabled] == true || params[:enabled] == "true"

          result = if enabling
                     ingestion_cache.enable!.bind { enqueue_pending_webhooks }
          else
                     ingestion_cache.disable!
          end

          case result
          in Success(_)
            show
          in Failure(error)
            render json: { error: error.message }, status: :service_unavailable
          end
        end

        private

        def ingestion_cache
          @ingestion_cache ||= Pay::Webhook::Ingestion::Cache.new
        end

        def enqueue_pending_webhooks
          Pay::Webhook::Service.new.enqueue_pending_webhooks
        end
      end
    end
  end
end
