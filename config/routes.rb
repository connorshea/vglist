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
  end

  resources :game_purchases, except: [:edit, :new] do
    post :bulk_update, on: :collection
  end

  resources :users do
    get :index, on: :collection
    get :show, on: :member
    get :statistics, on: :member
    post :update_role, on: :member
    delete :remove_avatar, on: :member
    post :connect_steam, on: :member
    delete :disconnect_steam, on: :member
    post :steam_import, on: :member
    delete :reset_game_library, on: :member
    get '/compare/:user_id...:other_user_id', as: :compare, action: :compare, on: :collection
  end

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

  namespace :search do
    get :index, as: '/', path: '/'
  end

  namespace :settings do
    get :profile, as: '/', path: '/'
    get :account
    get :connections
  end

  get '/about', to: 'static_pages#about'
end
