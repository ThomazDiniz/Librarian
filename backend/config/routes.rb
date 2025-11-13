Rails.application.routes.draw do
  post "signup", to: "auth#signup"
  post "login", to: "auth#login"
  delete "logout", to: "auth#logout"

  resources :books
  resources :borrowings, only: %i[index show create] do
    member do
      patch :return, to: "borrowings#return_book"
    end
  end

  get "dashboard", to: "dashboards#show"

  get "up" => "rails/health#show", as: :rails_health_check
end
