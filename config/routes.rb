require "sidekiq/web"

Rails.application.routes.draw do
  # Sidekiq Web UI
  mount Sidekiq::Web => "/sidekiq"

  # Health check
  get "up" => "rails/health#show", as: :rails_health_check
end
