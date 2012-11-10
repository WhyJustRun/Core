WhyJustRun::Application.routes.draw do
  root :to => "home#index"
	resources :events
	
	# :version => /[^\/]*/ is needed to allow dots in the IOF XML version #
	version_constraint = { :version => /[^\/]*/ }
	match 'iof/:version/events/:id/start_list' => 'events#start_list', :constraints => version_constraint, :as => :event
	match 'iof/:version/organization_list' => 'clubs#index', :constraints => version_constraint, :as => :event
	match 'iof/:version/events/:id/entry_list' => 'events#entry_list', :constraints => version_constraint, :as => :event
	
	match 'iof/:version/users/event_list/limit/:limit' => 'events#event_list_for_user', :constraints => version_constraint, :as => :event
	match 'iof/:version/users/event_list' => 'events#event_list_for_user', :constraints => version_constraint, :as => :event

	match 'iof/:version/clubs/:club_id/event_list' => 'events#index', :constraints => version_constraint, :as => :event

	match 'iof/:version/events/:id/result_list' => 'events#result_list', :constraints => version_constraint, :as => :event, :via => "get"
	match 'iof/:version/events/:id/result_list' => 'events#process_result_list', :constraints => version_constraint, :as => :event, :via => "post"
	
	match 'club/:club_id/events' => 'events#index', :as => :event
	match 'club/:club_id/participation_report' => 'clubs#participant_counts', :as => :club
	
  # The priority is based upon order of creation:
  # first created -> highest priority.

  # Sample of regular route:
  #   match 'products/:id' => 'catalog#view'
  # Keep in mind you can assign values other than :controller and :action

  # Sample of named route:
  #   match 'products/:id/purchase' => 'catalog#purchase', :as => :purchase
  # This route can be invoked with purchase_url(:id => product.id)

  # Sample resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Sample resource route with options:
  #   resources :products do
  #     member do
  #       get 'short'
  #       post 'toggle'
  #     end
  #
  #     collection do
  #       get 'sold'
  #     end
  #   end

  # Sample resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Sample resource route with more complex sub-resources
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', :on => :collection
  #     end
  #   end

  # Sample resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end

  # You can have the root of your site routed with "root"
  # just remember to delete public/index.html.
  # root :to => 'welcome#index'

  # See how all your routes lay out with "rake routes"

  # This is a legacy wild controller route that's not recommended for RESTful applications.
  # Note: This route will make all actions in every controller accessible via GET requests.
  # match ':controller(/:action(/:id(.:format)))'
end
