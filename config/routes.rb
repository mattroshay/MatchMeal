Rails.application.routes.draw do
  devise_for :users
  root to: "pages#home"

  # Health check route
  get "up" => "rails/health#show", as: :rails_health_check

  # Defines the root path route ("/")
  # root "posts#index"

  post 'recipes/search', to: 'recipes#search', as: :search_recipes
  get 'recipes/generate_recipes', to: 'recipes#generate_recipes', as: :generate_recipes

  resources :recipes do
    resources :favorites, only: [:create, :destroy, :index]
    # Add a custom route for ingredient detection
    get 'detect_ingredients', on: :collection

    # Add a custom POST route with a named route
    post 'process_image', to: 'recipes#process_image', on: :collection, as: :process_image
    delete 'clear_ingredients', to: 'recipes#clear_ingredients', on: :collection, as: :clear_ingredients
  end

  resources :favorites, only: [:index]

  resources :users, only: [:show, :edit, :update]
end
