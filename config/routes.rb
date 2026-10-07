# frozen_string_literal: true

# For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
Rails.application.routes.draw do
  # Health check
  get '/health', to: 'api/health#show'

  # ActiveStorage's direct upload endpoint has no authentication and hands out
  # presigned upload URLs for the public bucket. Nothing in the app uses it, so
  # shadow it here (app routes are matched before the engine's) instead of
  # disabling `draw_routes` and redrawing the blob/representation routes and
  # URL helpers we do need.
  post '/rails/active_storage/direct_uploads', to: proc { [404, {}, []] }

  # JWT Authentication endpoints for the Vue SPA frontend
  namespace :api do
    post 'auth/sign_in', to: 'auth#sign_in'
    post 'auth/sign_up', to: 'auth#sign_up'
    delete 'auth/sign_out', to: 'auth#sign_out'
    get 'auth/me', to: 'auth#me'
  end

  # Devise routes (for email confirmation, password reset via email links)
  devise_for :users, controllers: {
    confirmations: 'users/confirmations',
    passwords: 'users/passwords'
  }, skip: [:sessions, :registrations]

  # OAuth routes (Doorkeeper)
  scope :settings do
    use_doorkeeper do
      controllers applications: 'oauth/applications',
                  authorized_applications: 'oauth/authorized_applications',
                  authorizations: 'oauth/authorizations'
    end
  end

  # Execute GraphQL queries posted to '/graphql'.
  post "/graphql", to: "graphql#execute"

  # For exposing the OpenSearch XML definition
  get '/opensearch', to: 'static_pages#opensearch', defaults: { format: :xml }

  # SPA fallback — serve the Vue frontend's index.html for all unmatched routes.
  # This must be the last route. In production, Rails serves the built frontend
  # from public/. In development, the Vite dev server handles frontend routes.
  get '*path', to: 'spa#index', constraints: ->(req) {
    !req.xhr? && req.format.html?
  }
  root to: 'spa#index'
end
