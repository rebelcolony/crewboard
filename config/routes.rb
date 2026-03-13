Rails.application.routes.draw do
  root "dashboard#show"

  resource :session, only: [ :new, :create, :destroy ]
  resource :registration, only: [ :new, :create ]
  resources :projects
  resources :crew_members

  # Stripe
  get "pricing", to: "pricing#show"
  resources :checkouts, only: [ :create ]
  resource :billing, only: [ :show ]

  # Admin
  namespace :admin do
    root "dashboard#show"
    resources :accounts
    resources :managers
    resources :projects
    resources :crew_members
    resources :subscriptions, only: [ :index, :show ]
  end

  get "up" => "rails/health#show", as: :rails_health_check
end
