Rails.application.routes.draw do
  root "home#index"

  get "/public-screen",
      to: "public_screens#index",
      as: :public_screen

  get "/satisfaction-survey/:survey_token",
      to: "satisfaction_surveys#show",
      as: :satisfaction_survey

  post "/satisfaction-survey/:survey_token",
       to: "satisfaction_surveys#create",
       as: :submit_satisfaction_survey

  resources :users, only: [ :index, :new, :create, :edit, :update, :destroy ]
  resources :queue_services, only: [ :index, :new, :create, :edit, :update, :destroy ]
  resources :service_windows, only: [ :index, :new, :create, :edit, :update, :destroy ]

  get "/dashboard",
      to: "dashboard#index",
      as: :dashboard

  post "/dashboard/ai-assistant",
       to: "dashboard/ai_assistant#create",
       as: :dashboard_ai_assistant

  get "/ai-recommendations",
      to: "ai_recommendations#index",
      as: :ai_recommendations

  get "/agent-queue",
      to: "agent_queues#index",
      as: :agent_queue

  post "/agent-queue/call-next",
       to: "agent_queues#call_next",
       as: :call_next_ticket

  patch "/agent-queue/tickets/:id/start",
        to: "agent_queues#start_attention",
        as: :start_ticket_attention

  patch "/agent-queue/tickets/:id/finish",
        to: "agent_queues#finish_attention",
        as: :finish_ticket_attention

  patch "/agent-queue/tickets/:id/no-show",
        to: "agent_queues#mark_no_show",
        as: :mark_ticket_no_show

  get "/tickets/reception", to: "tickets#reception", as: :tickets_reception
  post "/tickets", to: "tickets#create", as: :tickets
  patch "/tickets/:id/cancel",
        to: "tickets#cancel",
        as: :cancel_ticket

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
