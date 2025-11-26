Rails.application.routes.draw do
  # Installation wizard (only available when system is not installed)
  get "/installation", to: "installation#show", as: :installation
  post "/installation", to: "installation#create"

  resource :session
  resources :users
  resources :passwords, param: :token
  get "/confirmations/:token", to: "confirmations#show", as: :confirmation

  # Personal center (my namespace)
  namespace :my do
    root to: "dashboard#show" # Personal center homepage (/my)

    resource :profile, only: [ :show, :edit, :update ], controller: "profile" # Personal information (/my/profile)
    resource :security, only: [ :show, :update ], controller: "security" # Security settings (/my/security)
    resources :sessions, only: [ :index, :destroy ] do # Session management (/my/sessions)
      collection do
        post "destroy_all_others" # Logout all other devices
      end
    end
  end

  # Admin namespace
  namespace :admin do
    root to: "dashboard#index"
    resources :users do
      collection do
        post "batch_destroy"
        post "batch_assign_role"
        post "batch_remove_role"
      end
    end
    resources :roles
    resources :policies, only: [ :index, :show ] # Policy class documentation (read-only)
    resources :system_configs, only: [ :index, :edit, :update ]
    resources :audit_logs, only: [ :index, :show ]
  end

  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Tech stack rules documentation
  get "/tech-stack/:id", to: "tech_stack#show", as: :tech_stack_rule

  # Development experiences documentation
  resources :experiences, only: [ :index, :show ], path: "experiences"

  # Defines the root path route ("/")
  root "welcome#index"
end
