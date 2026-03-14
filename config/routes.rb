# For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
Rails.application.routes.draw do
  # Health check
  get '/health', to: 'api/health#show'

  # JWT Authentication endpoints for the Vue SPA frontend
  namespace :api do
    post 'auth/sign_in', to: 'auth#sign_in'
    post 'auth/sign_up', to: 'auth#sign_up'
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
end
