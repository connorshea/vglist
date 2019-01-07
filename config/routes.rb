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

  resources :games

  resources :releases, only: [:index, :show]

  resources :users, only: [:index, :show]

  resources :platforms, only: [:index, :show]

  resources :genres

  resources :companies
end
