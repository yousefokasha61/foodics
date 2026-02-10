require "sidekiq/web"

Rails.application.routes.draw do
  # Sidekiq Web UI
  mount Sidekiq::Web => "/sidekiq"

  # Health check
  get "up" => "rails/health#show", as: :rails_health_check

  namespace :api do
    namespace :v1 do
      namespace :pay do
        # Receiving money - POST /api/v1/pay/webhook
        # Headers: X-Wallet-ID, X-Bank
        resource :webhook, only: [ :create ], controller: "webhook"

        # Sending money - POST /api/v1/pay/transfers/:wallet_id
        post "transfers/:wallet_id", to: "transfers#create", as: :transfer
      end

      # Admin - ingestion control
      # GET/PATCH /api/v1/admin/ingestion
      namespace :admin do
        resource :ingestion, only: [ :show, :update ]
      end
    end
  end
end
