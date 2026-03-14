Rails.application.routes.draw do
  root "pages#home"
  get "dashboard", to: "dashboard#show", as: :dashboard

  resource :session, only: [ :new, :create, :destroy ]
  resource :registration, only: [ :new, :create ]
  resource :password_reset, only: [ :new, :create, :edit, :update ]
  resource :profile, only: [ :show, :update ]
  resources :projects
  resources :crew_members
  resources :invites, only: [ :index, :create, :destroy ]
  get "invites/:token/accept", to: "invites#accept", as: :accept_invite
  post "invites/:token/accept", to: "invites#register"

  # Stripe
  get "pricing", to: "pricing#show"
  resources :checkouts, only: [ :create ] do
    post :swap, on: :collection
  end
  resource :billing, only: [ :show ] do
    post :portal, on: :member
  end

  # Admin
  namespace :admin do
    root "dashboard#show"
    resources :accounts
    resources :subscriptions, only: [ :index, :show ]
  end

  # Legal
  get "privacy", to: "pages#privacy"
  get "terms", to: "pages#terms"
  get "cookies", to: "pages#cookies_policy"

  get "up" => "rails/health#show", as: :rails_health_check

  mount LetterOpenerWeb::Engine, at: "/letter_opener" if Rails.env.development?
end
