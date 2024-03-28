Rails.application.routes.draw do
  devise_for :users, :controllers => { :registrations => 'users/registrations' }

  root :to => "home#about_whyjustrun"
  get 'pages/privacy_policy', to: 'pages#privacy_policy'
  get 'about/orienteering', to: 'home#about_orienteering'
  get 'events/calendar', to: 'events#calendar'
  get 'clubs/map', to: 'clubs#map'
  get 'users/sign_in_clubsite', to: 'users#sign_in_clubsite'
  get 'users/sign_out_clubsite', to: 'users#sign_out_clubsite'
  # must be an integer
  user_id_constraint = { :user_id => /\b\d+\b/ }
  get 'users/:user_id', to: 'users#show', :constraints => user_id_constraint, :as => :user
  put 'users/:user_id', to: 'users#send_message', :constraints => user_id_constraint

  # :iof_version => /[^\/]*/ is needed to allow dots in the IOF XML version #
  version_constraint = { :iof_version => /[^\/]*/ }
  get 'iof/:iof_version/events/:id/start_list', to: 'events#start_list', :constraints => version_constraint
  get 'iof/:iof_version/organization_list', to: 'clubs#index', :constraints => version_constraint
  get 'iof/:iof_version/competitor_list', to: 'users#competitor_list', :constraints => version_constraint
  get 'iof/:iof_version/events/:id/entry_list', to: 'events#entry_list', :constraints => version_constraint

  get 'iof/:iof_version/users/event_list/limit/:limit', to: 'events#event_list_for_user', :constraints => version_constraint
  get 'iof/:iof_version/users/event_list', to: 'events#event_list_for_user', :constraints => version_constraint

  get 'iof/:iof_version/clubs/:club_id/event_list', to: 'events#index', :constraints => version_constraint

  # TODO TMP
  get 'iof/result_list', to: 'results#update_result_list'
  get 'iof/:iof_version/events/:id/result_list', to: 'results#result_list', :constraints => version_constraint
  post 'iof/:iof_version/events/:id/result_list', to: 'results#process_result_list', :constraints => version_constraint
  post 'iof/:iof_version/events/:id/live_result_list', to: 'results#update_live_result_list', :constraints => version_constraint
  get 'iof/:iof_version/events/:id/live_result_list', to: 'results#live_result_list', :constraints => version_constraint

  get 'events', to: 'events#index', format: true
  get 'club/:club_id/events', to: 'events#index', format: true
  get 'club/:club_id/participation_report', to: 'clubs#participant_counts'

  get 'api/maps', to: 'maps#index'

  post 'api/redactor/uploadImage', to: 'redactor#upload_image'
  post 'api/redactor/uploadFile', to: 'redactor#upload_file'

  # Handle all CORS OPTIONS requests
  match '*all', to: 'application#cors', via: [:options]
  
  get ':name', to: 'short_links#show'
end
