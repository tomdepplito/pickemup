Pickemup::Application.routes.draw do
  root to: 'home#index'
  scope :auth do
    get '/github/callback', to: 'sessions#github'
    get '/linkedin/callback', to: 'sessions#linkedin'
    get '/stackexchange/callback', to: 'sessions#stackoverflow'
  end
  scope 'sessions', controller: :sessions do
    get :sign_in
    get :sign_up
  end
  scope '/', controller: :home do
    get :about
    get :contact
    get :pricing
    post :create_contact
    get :terms_of_service
    get :privacy_policy
    get :get_matches
  end
  get "log_out" => "sessions#destroy", as: "log_out"
  resources :users, only: [:edit, :update] do
    member do
      get :listings
      get :resume
      get :skills
      get :preferences
      get :get_preference
      put :update_preference
      put :toggle_activation
      get :search_jobs
    end
    resources :conversations, only: [:index, :show, :destroy, :update] do
      member do
        put :untrash
      end
    end
    resources :messages, except: [:edit, :update, :destroy]
  end
  resources :companies, except: [:new] do
    collection do
      get ':email/validate_company', to: 'companies#validate_company', as: :validate_company
    end
    member do
      put :toggle_activation
    end
    get :purchase_options, to: 'subscriptions#purchase_options'
    get :get_users
    resources :conversations, only: [:index, :show, :destroy, :update] do
      member do
        put :untrash
      end
    end
    resources :tech_stacks, only: [:index, :new, :create, :edit, :destroy] do
      member do
        get :retrieve_tech_stack
        put :update_tech_stack
      end
    end
    resources :job_listings do
      member do
        get :search_users
        get :retrieve_listing
        put :update_listing
        put :toggle_active
      end
      collection do
        get :guide
      end
    end
    resources :messages, except: [:edit, :update, :destroy]
    resources :subscriptions, except: [:destroy] do
      member do
        get :edit_card
        put :edit_card
      end
    end
  end
  post "/company_log_in" => "sessions#company"
  match '/subscriptions_listener' => 'subscriptions#listener', via: :all
  require 'sidekiq/web'
  mount Sidekiq::Web, at: '/sidekiq'
  mount JasmineRails::Engine => "/specs" if defined?(JasmineRails)
end
