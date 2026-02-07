# frozen_string_literal: true

module Api
  module V1
    module Admin
      class IngestionsController < BaseController
        # GET /api/v1/admin/ingestion
        def show
          render json: { enabled: true }
        end

        # PATCH /api/v1/admin/ingestion
        def update
          head :ok
        end
      end
    end
  end
end
