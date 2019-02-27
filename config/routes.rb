# For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
Rails.application.routes.draw do
  devise_for :users, controllers: {
    confirmations: 'users/confirmations',
    passwords: 'users/passwords',
    registrations: 'users/registrations',
    sessions: 'users/sessions'
  }

  get 'home/index'

  root 'home#index'

  resources :games do
    get :search, on: :collection
    post :add_game_to_library, on: :member
    delete :remove_game_from_library, on: :member
    delete :remove_cover, on: :member
  end

  resources :users do
    get :index, on: :collection
    get :show, on: :member
    post :update_role, on: :member
    delete :remove_avatar, on: :member
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

  namespace :settings do
    get :profile, as: '/', path: '/'
    get :account
  end
end
