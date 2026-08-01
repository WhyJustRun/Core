Rails.application.routes.draw do
  # ---------------------------------------------------------------------------
  # Shared API routes, reachable on the apex domain and on club domains.
  # ---------------------------------------------------------------------------

  # :iof_version => /[^\/]*/ is needed to allow dots in the IOF XML version #
  version_constraint = { :iof_version => /[^\/]*/ }
  get 'iof/:iof_version/events/:id/start_list', to: 'events#start_list', :constraints => version_constraint
  get 'iof/:iof_version/organization_list', to: 'clubs#index', :constraints => version_constraint
  get 'iof/:iof_version/competitor_list', to: 'users#competitor_list', :constraints => version_constraint
  get 'iof/:iof_version/events/:id/entry_list', to: 'events#entry_list', :constraints => version_constraint

  get 'iof/:iof_version/users/event_list/limit/:limit', to: 'events#event_list_for_user', :constraints => version_constraint
  get 'iof/:iof_version/users/event_list', to: 'events#event_list_for_user', :constraints => version_constraint

  get 'iof/:iof_version/clubs/:club_id/event_list', to: 'events#index', :constraints => version_constraint

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

  # ---------------------------------------------------------------------------
  # Club websites: any host other than the apex domain. The trailing catch-all
  # keeps club-domain requests from falling through to apex routes.
  # ---------------------------------------------------------------------------
  constraints(ClubDomainConstraint.new) do
    scope module: :clubsite do
      get 'robots.txt', to: 'robots#show', format: false
      get '/', to: 'pages#home', as: :clubsite_root

      # Events
      get 'events(/index(/:date))', to: 'events#index', as: :clubsite_events
      get 'events/listing', to: 'events#listing'
      get 'events/view/:id', to: 'events#show', as: :clubsite_event
      get 'events/results/:id', to: 'events#show'
      get 'events/map/:id', to: 'events#map'
      get 'events/rendering/:id', to: 'events#rendering'
      get 'events/planner', to: 'events#planner'
      get 'events/printableEntries/:id', to: 'events#printable_entries'
      get 'events/edit(/:id)', to: 'events#edit'
      match 'events/edit(/:id)', to: 'events#save', via: [:post, :patch]
      post 'events/delete/:id', to: 'events#destroy'
      get 'events/uploadMaps/:id', to: 'events#upload_maps'
      get 'events/editResults/:id', to: 'events#edit_results'
      post 'events/editResults/:id', to: 'events#update_results'
      post 'events/toggle_live_results_visibility/:id/:visible', to: 'events#toggle_live_results_visibility'

      # Maps
      get 'maps(/index)', to: 'maps#index', as: :clubsite_maps
      get 'maps/view/:id', to: 'maps#show', as: :clubsite_map
      get 'maps/report', to: 'maps#report'
      get 'maps/download/:id', to: 'maps#download'
      get 'maps/rendering/:id(/:thumbnail)', to: 'maps#rendering'
      get 'maps/edit(/:id)', to: 'maps#edit'
      match 'maps/edit(/:id)', to: 'maps#save', via: [:post, :patch]
      post 'maps/delete/:id', to: 'maps#destroy'
      post 'maps/update/:id/:lat/:lng', to: 'maps#update_location',
           constraints: { lat: /-?[\d.]+/, lng: /-?[\d.]+/ }

      # Courses
      get 'courses/view/:id', to: 'courses#show', as: :clubsite_course
      get 'courses/map/:id(/:thumbnail)', to: 'courses#map'
      post 'courses/register/:course_id(/:user_id)', to: 'courses#register'
      post 'courses/unregister/:course_id(/:user_id)', to: 'courses#unregister'
      post 'courses/delete/:id', to: 'courses#destroy'
      post 'courses/uploadMap/:id', to: 'courses#upload_map'

      # Results
      get 'results(/index)', to: 'results#index', as: :clubsite_results
      post 'results/editRegistrantComment', to: 'results#edit_registrant_comment'
      post 'results/delete/:id', to: 'results#destroy'

      # User admin and pickers
      get 'users(/index)', to: 'users#index'
      post 'users/add', to: 'users#create'
      post 'users/merge/:target_id/:source_id', to: 'users#merge'
      get 'users/showDuplicates', to: 'users#show_duplicates'
      post 'users/showDuplicates', to: 'users#show_duplicates'

      # Sign-in/out via the apex site (legacy CakePHP URL shapes preserved)
      get 'users/login', to: 'sessions#new'
      get 'users/logout', to: 'sessions#destroy'
      get 'users/logoutComplete', to: 'sessions#logout_complete'
      get 'users/localLogin', to: 'sessions#new'
      get 'sso/consume', to: 'sessions#consume'
      get 'users/register', to: redirect { |_params, _request| "#{Settings.coreURL.chomp('/')}/users/sign_up" }, status: 301
      get 'users/view/:id', to: redirect { |params, _request| "#{Settings.coreURL.chomp('/')}/users/#{params[:id]}" }, status: 301

      # Club admin
      get 'clubs(/index)', to: 'clubs#index'
      get 'clubs/edit', to: 'clubs#edit'
      match 'clubs/edit', to: 'clubs#update', via: [:post, :patch]

      get 'series(/index)', to: 'series#index', as: :clubsite_series
      get 'series/edit(/:id)', to: 'series#edit'
      match 'series/edit(/:id)', to: 'series#update', via: [:post, :patch]

      get 'roles(/index)', to: 'roles#index', as: :clubsite_roles
      get 'roles/edit(/:id)', to: 'roles#edit'
      match 'roles/edit(/:id)', to: 'roles#update', via: [:post, :patch]

      get 'mapStandards(/index)', to: 'map_standards#index'
      get 'map_standards(/index)', to: 'map_standards#index'
      get 'mapStandards/edit(/:id)', to: 'map_standards#edit'
      match 'mapStandards/edit(/:id)', to: 'map_standards#update', via: [:post, :patch]
      post 'mapStandards/delete/:id', to: 'map_standards#destroy'

      get 'memberships(/index)', to: 'memberships#index'
      get 'memberships/edit(/:id)', to: 'memberships#edit'
      match 'memberships/edit(/:id)', to: 'memberships#update', via: [:post, :patch]
      post 'memberships/delete/:id', to: 'memberships#destroy'

      get 'officials(/index)', to: 'officials#index'
      post 'officials/add', to: 'officials#create'
      get 'officials/edit/:id', to: 'officials#edit'
      match 'officials/edit/:id', to: 'officials#update', via: [:post, :patch]
      post 'officials/delete/:id', to: 'officials#destroy'

      get 'privileges(/index)', to: 'privileges#index'
      post 'privileges/add', to: 'privileges#create'
      post 'privileges/delete/:id', to: 'privileges#destroy'

      get 'resources(/index)', to: 'resources#index'
      post 'resources/add', to: 'resources#create'
      post 'resources/delete/:id', to: 'resources#destroy'

      # Pages and content blocks. The jEditable editors post to the legacy
      # CakePHP URLs (/pages/edit, /contentBlocks/edit).
      post 'pages/add', to: 'pages#create'
      post 'pages/edit', to: 'pages#update'
      post 'pages/delete/:id', to: 'pages#destroy'
      post 'contentBlocks/edit', to: 'content_blocks#update'
      get 'pages/:page', to: 'pages#show', as: :clubsite_page
      get 'Pages/:page', to: 'pages#show'

      match '*unmatched', to: 'errors#not_found', via: :all, format: false
    end
  end

  # ---------------------------------------------------------------------------
  # Apex (whyjustrun.ca) routes
  # ---------------------------------------------------------------------------
  devise_for :users, :controllers => {
    :registrations => 'users/registrations',
    :sessions => 'users/sessions',
    :passwords => 'users/passwords'
  }
  get 'sso/authorize', to: 'sso#authorize'
  get 'sso/logout', to: 'sso#logout'

  root :to => "home#about_whyjustrun"
  get 'robots.txt', to: 'home#robots', format: false
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

  get 'clubsite/:club_id', to: 'clubs#show_clubsite', as: :clubsite

  get ':name', to: 'short_links#show'
end
