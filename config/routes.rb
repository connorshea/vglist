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
  end

  resources :releases

  resources :users do
    get :index, on: :collection
    get :show, on: :member
    post :update_role, on: :member
  end

  resources :platforms do
    get :search, on: :collection
  end

  resources :genres do
    get :search, on: :collection
  end

  resources :companies do
    get :search, on: :collection
  end
end
