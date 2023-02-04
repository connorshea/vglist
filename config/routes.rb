# typed: strict
# For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
Rails.application.routes.draw do
  # Put this at the top for ~performance~
  root 'home#index'

  devise_for :users, controllers: {
    confirmations: 'users/confirmations',
    passwords: 'users/passwords',
    registrations: 'users/registrations',
    sessions: 'users/sessions'
  }

  get 'home/index'

  resources :games do
    get :search, on: :collection
    post :add_game_to_library, on: :member
    delete :remove_game_from_library, on: :member
    delete :remove_cover, on: :member
    post :favorite, on: :member
    delete :unfavorite, on: :member
    get :favorited, on: :member
    # Path like `/games/:id/merge/:game_b_id`
    post :merge, on: :member, path: 'merge/:game_b_id'

    post :add_to_wikidata_blocklist, on: :member
  end

  resources :game_purchases, except: [:edit, :new] do
    post :bulk_update, on: :collection
  end

  resources :users do
    get :index, on: :collection
    get :search, on: :collection
    get :show, on: :member
    get :statistics, on: :member
    get :activity, on: :member
    get '/compare/:user_id...:other_user_id', as: :compare, action: :compare, on: :collection
    post :update_role, on: :member
    delete :remove_avatar, on: :member
    post :connect_steam, on: :member
    delete :disconnect_steam, on: :member
    post :steam_import, on: :member
    delete :reset_game_library, on: :member

    get :favorites, on: :member
    get :following, on: :member
    get :followers, on: :member
    post :follow, to: 'relationships#create'
    delete :unfollow, to: 'relationships#destroy'
    post :reset_token, on: :collection
    post :ban, on: :member
    post :unban, on: :member
  end

  namespace :activity do
    get :global, as: '/', path: '/'
    get :following
  end

  namespace :admin do
    get :dashboard, as: '/', path: '/'
    get :wikidata_blocklist, path: 'wikidata'
    delete :remove_from_wikidata_blocklist, path: 'wikidata/:wikidata_id/remove'

    get :new_steam_blocklist, path: 'steam/new'
    get :steam_blocklist, path: 'steam'
    post :add_to_steam_blocklist, path: 'steam'
    delete :remove_from_steam_blocklist, path: 'steam/:steam_app_id/remove'

    get :games_without_wikidata_ids

    resources :unmatched_games, param: :external_service_id, only: [:index, :destroy]
  end

  resources :events, only: :destroy

  resources :platforms do
    get :search, on: :collection
  end

  resources :engines do
    get :search, on: :collection
  end

  resources :genres do
    get :search, on: :collection
  end

  resources :companies do
    get :search, on: :collection
  end

  resources :series do
    get :search, on: :collection
  end

  resources :stores do
    get :search, on: :collection
  end

  namespace :search do
    get :index, as: '/', path: '/'
  end

  namespace :settings do
    get :profile, as: '/', path: '/'
    get :account
    get :import
    get :export
    get :export_as_json
    get :api_token, defaults: { format: :json }
  end

  scope :settings do
    # This is contributed by Doorkeeper, but Sorbet doesn't know that so we have to hack around it.
    T.unsafe(self).use_doorkeeper do
      T.unsafe(self).controllers applications: 'oauth/applications',
                                 authorized_applications: 'oauth/authorized_applications',
                                 authorizations: 'oauth/authorizations'
    end
  end

  # Implement the .well-known/change-password URL.
  get '.well-known/change-password', to: redirect('/settings/account')

  get '/about', to: 'static_pages#about'

  # For exposing the OpenSearch XML definition
  get '/opensearch', to: 'static_pages#opensearch', defaults: { format: :xml }

  # API routes
  get '/graphiql', to: 'static_pages#graphiql'
  # Execute GraphQL queries posted to '/graphql'.
  post "/graphql", to: "graphql#execute"
end
