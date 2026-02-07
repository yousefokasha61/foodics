require "sidekiq/web"

Rails.application.routes.draw do
  # Sidekiq Web UI
  mount Sidekiq::Web => "/sidekiq"

  # Health check
  get "up" => "rails/health#show", as: :rails_health_check

  namespace :api do
    namespace :v1 do
      resources :wallets, only: [] do
        # Receiving money - POST /api/v1/wallets/:wallet_id/webhooks?bank=foodics
        resources :webhooks, only: [ :create ]

        # Sending money - POST /api/v1/wallets/:wallet_id/payments
        resources :payments, only: [ :create ]
      end

      # Admin - ingestion control
      # GET/PATCH /api/v1/admin/ingestion
      namespace :admin do
        resource :ingestion, only: [ :show, :update ]
      end
    end
  end
end
