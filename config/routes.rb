Rails.application.routes.draw do
  root "home#index"

  resources :users, only: [:index]
  resources :queue_services, only: [:index]
  resources :service_windows, only: [:index]

  get "/login", to: "sessions#new", as: :login
  post "/login", to: "sessions#create"
  delete "/logout", to: "sessions#destroy", as: :logout

  get "up" => "rails/health#show", as: :rails_health_check
end
