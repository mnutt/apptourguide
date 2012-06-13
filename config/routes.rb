AppTourGuide::Application.routes.draw do
  resources :tip_lists
  match 'tip_lists/:id', :to => "tip_lists#show", :via => "options"

  root :to => "home#index"
end
