Rails.application.routes.draw do
  devise_for :users, controllers: {
    registrations: "users/registrations"
  }
  get "up" => "rails/health#show", :as => :rails_health_check

  namespace :api do
    namespace :v1 do
      get "status", to: "status#show"
    end
  end

  get "ping", to: "welcome#ping"
  root "welcome#index"
end
