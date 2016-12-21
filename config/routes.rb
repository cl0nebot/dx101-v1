Web::Application.routes.draw do 

  require 'sidekiq/web'
  constraints lambda {|request| Sidekiq::AuthConstraint.admin?(request)} do
    mount Sidekiq::Web => '/sidekiq'
  end

  get '/feed', to: redirect("http://support.101.net/rss/News/Feed", status: 301)
  get '/feed/', to: redirect("http://support.101.net/rss/News/Feed", status: 301)

  root 'pages#index'
  get :agents, to: 'pages#agents'
  get '/markets(/:quantity_currency(/:rate_currency))', to: 'pages#markets', as: :markets
  get :api, to: 'pages#api'
  #get :cold, to: 'pages#cold-wallets'
  #get :features, to: 'pages#features'
  get :fees, to: 'pages#fees'
  get :privacy, to: 'pages#privacy'
  get :terms, to: 'pages#terms'
  get :values, to: 'pages#values'
  get :onboard, to: 'pages#onboard'
  
  # User Registration / Authing
  get :signup, to: 'users#new'
  post :signup, to: 'users#create'
  get :thanks, to: 'users#thanks'
  get :verify, to: 'users#verify'
  get :resend, to: 'users#resend'
  post :resend, to: 'users#resend'
  get :recover, to: 'users#recover'
  post :recover, to: 'users#recover'
  get :reset, to: 'users#reset'
  patch :reset, to: 'users#reset'
  get :continue, to: 'users#continue'
  patch :continue, to: 'users#continue'
  get :login, to: 'users#login'
  post :login, to: 'users#login'
  get :mfa, to: 'users#mfa'
  post :mfa, to: 'users#mfa'
  get :logout, to: 'users#logout'

  # Locations
  get :locations, to: 'locations#index'

  namespace :panel do
    get '/', to: 'dashboard#show'
    resource :dashboard, controller: :dashboard, only: [:show] do
      collection do
        get :ping
      end
    end
    resource :account, controller: :account do
      get :enable_mfa
      get :disable_mfa
    end
    resource :wallet, controller: :wallet, only: [:show] do 
      collection do
        get :withdraw
        post :withdraw
        get :cancel
      end
      resources :addresses, controller: :crypto_addresses do
        member do
          get :hide
        end
      end
    end
    resources :trades do
      member do
        get :cancel
        get :activate
      end
      collection do
        get :history
        post :units
        post :filters
      end
    end
  end

  namespace :admin do
    resource :dashboard, controller: :dashboard, only: [:show]
    resources :users do
      member do
        patch :add_funds
      end
    end
    resource :finance, controller: :finance, only: [:show]
    resources :withdraws, only: [:index] do
      collection do
        post :batch
      end
      member do
        get :cancel
      end
    end
  end

  namespace :api do
    post 'listener/deposit', to: 'listener#deposit'
    post 'listener/withdraw', to: 'listener#withdraw'
  end

end
