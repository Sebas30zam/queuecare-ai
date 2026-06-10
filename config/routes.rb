Rails.application.routes.draw do
  root "home#index"

  resources :users, only: [:index]
  resources :queue_services, only: [:index]
  resources :service_windows, only: [:index]

  get "/agent-queue",
      to: "agent_queues#index",
      as: :agent_queue

  post "/agent-queue/call-next",
       to: "agent_queues#call_next",
       as: :call_next_ticket

  get "/tickets/reception", to: "tickets#reception", as: :tickets_reception
  post "/tickets", to: "tickets#create", as: :tickets

  get "/self-service",
      to: "self_service_tickets#new",
      as: :self_service

  post "/self-service/tickets",
       to: "self_service_tickets#create",
       as: :self_service_tickets

  get "/login", to: "sessions#new", as: :login
  post "/login", to: "sessions#create"
  delete "/logout", to: "sessions#destroy", as: :logout

  get "up" => "rails/health#show", as: :rails_health_check
end
