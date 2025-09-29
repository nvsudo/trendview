Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Authentication routes
  resource :session, only: [:new, :create, :destroy]
  get "/login", to: "sessions#new"
  post "/login", to: "sessions#create"
  delete "/logout", to: "sessions#destroy"

  # User registration
  resources :users, only: [:new, :create]
  get "/signup", to: "users#new"
  post "/signup", to: "users#create"

  # Main application routes
  root "dashboard#index"

  # Trading routes
  resources :trades do
    member do
      patch :close
    end
  end

  resources :trading_accounts, only: [:index, :show, :new, :create, :edit, :update]
  resources :securities, only: [:index, :show] do
    resources :user_stock_analyses, except: [:index]
  end

  # Dashboard and analytics
  get "/analytics", to: "dashboard#analytics"
  get "/portfolio", to: "dashboard#portfolio"
end
