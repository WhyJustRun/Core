WhyJustRun::Application.routes.draw do
  devise_for :users, :controllers => { :registrations => 'users/registrations', :omniauth_callbacks => "users/omniauth_callbacks" }

  root :to => "home#index"
  get 'events/calendar', to: 'events#calendar'
  get 'clubs/map', to: 'clubs#map'
  get 'users/sign_in_clubsite', to: 'users#sign_in_clubsite'
  get 'users/sign_out_clubsite', to: 'users#sign_out_clubsite'
  # must be an integer
  user_id_constraint = { :user_id => /\b\d+\b/ }
  get 'users/:user_id', to: 'users#show', :constraints => user_id_constraint, :as => :user
  put 'users/:user_id', to: 'users#send_message', :constraints => user_id_constraint

  # :version => /[^\/]*/ is needed to allow dots in the IOF XML version #
  version_constraint = { :version => /[^\/]*/ }
  get 'iof/:version/events/:id/start_list', to: 'events#start_list', :constraints => version_constraint
  get 'iof/:version/organization_list', to: 'clubs#index', :constraints => version_constraint
  get 'iof/:version/events/:id/entry_list', to: 'events#entry_list', :constraints => version_constraint

  get 'iof/:version/users/event_list/limit/:limit', to: 'events#event_list_for_user', :constraints => version_constraint
  get 'iof/:version/users/event_list', to: 'events#event_list_for_user', :constraints => version_constraint

  get 'iof/:version/clubs/:club_id/event_list', to: 'events#index', :constraints => version_constraint
  get 'iof/:version/clubs/:club_id/event_list/:list_type', to: 'events#index', :constraints => version_constraint

  get 'iof/:version/events/:id/result_list', to: 'events#result_list', :constraints => version_constraint
  post 'iof/:version/events/:id/result_list', to: 'events#process_result_list', :constraints => version_constraint

  get 'events', to: 'events#index'
  get 'club/:club_id/events', to: 'events#index'
  get 'club/:club_id/participation_report', to: 'clubs#participant_counts'

end
