Rails.application.routes.draw do
  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  get "up" => "rails/health#show", as: :rails_health_check

  namespace :api do
    namespace :v1 do
      # Authentication
      post 'auth/login', to: 'authentication#login'
      post 'auth/signup', to: 'authentication#signup'
      
      # Dashboard
      get 'dashboard', to: 'dashboard#index'

      # Groups
      resources :groups do
        resources :expenses, only: [:index]
      end

      # Friends
      resources :friends, only: [:index, :create, :destroy] do
        member do
          patch :accept
        end
      end

      # Groups
      resources :groups, only: [:index, :create, :show, :update]

      # Expenses
      resources :expenses

      # Settlements & Activities & Notifications
      resources :settlements, only: [:index, :create]
      resources :activities, only: [:index]
      resources :notifications, only: [:index, :create] do
        member do
          patch :mark_as_read
        end
      end

      # Profile
      resource :profile, only: [:show, :update]
    end
  end
end
