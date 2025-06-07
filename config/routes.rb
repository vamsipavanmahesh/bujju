Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

    # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
    # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
    # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

    # Defines the root path route ("/")
    # root "posts#index"

    namespace :api do
    namespace :v1 do
      post "auth/google", to: "auth#google_sign_in"

      # Connections CRUD - only the routes we need
      resources :connections, only: [ :index, :show, :create, :update, :destroy ]

      # User preferences - only show and update
      resource :user_preferences, only: [ :show, :update ]

      # Onboarding settings - only show
      resource :onboarding, only: [ :show ]
    end
  end
end
