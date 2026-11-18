Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check
  get "health" => "health#show", as: :health_check

  root "pages#home"

  devise_for :users, controllers: {
    registrations: "users/registrations",
    omniauth_callbacks: "users/omniauth_callbacks"
  }
  get "sign-in", to: redirect("/users/sign_in")
  get "sign-up", to: redirect("/users/sign_up")

  # Handle picker + any missing age/consent details (Google sign-ups).
  get   "welcome", to: "profile_setup#edit", as: :profile_setup
  patch "welcome", to: "profile_setup#update"

  resource :account, only: [ :show, :destroy ] do
    get :export
  end
  resources :device_sessions, controller: "user_sessions", path: "account/sessions", only: [ :destroy ] do
    delete :others, on: :collection
  end

  # Pages built in later stages render a clear "being built" notice for now.
  # Each name maps to a fixed title; no user input selects a template.
  {
    watch: "Watch", community: "Community", support: "Talk to someone", give: "Give",
    blog: "Blog", events: "Upcoming events", store: "Store", team: "Our team",
    devotions: "Daily devotion", share_testimony: "Share testimony",
    privacy: "Privacy policy", terms: "Terms of use"
  }.each do |name, title|
    get name.to_s.dasherize, to: "pages#stub", as: name, defaults: { title: title }
  end

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  # root "posts#index"
end
