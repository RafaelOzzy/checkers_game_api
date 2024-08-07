Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.

  get "up" => "rails/health#show", as: :rails_health_check

  resources :games, only: [:create, :show] do
    member do
      post 'join'
      get 'status'
      get 'pieces'
      get 'moves/:piece_id', to: 'games#moves', as: 'moves'
      post 'move'
    end
  end

  root 'pages#index'
  # Defines the root path route ("/")
  # root "posts#index"
end
