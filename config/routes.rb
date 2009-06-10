ActionController::Routing::Routes.draw do |map|
  # The priority is based upon order of creation: first created -> highest priority.

  # Sample of regular route:
  #   map.connect 'products/:id', :controller => 'catalog', :action => 'view'
  # Keep in mind you can assign values other than :controller and :action

  # Sample of named route:
  #   map.purchase 'products/:id/purchase', :controller => 'catalog', :action => 'purchase'
  # This route can be invoked with purchase_url(:id => product.id)

  # Sample resource route (maps HTTP verbs to controller actions automatically):
  #   map.resources :products

  # Sample resource route with options:
  #   map.resources :products, :member => { :short => :get, :toggle => :post }, :collection => { :sold => :get }

  # Sample resource route with sub-resources:
  #   map.resources :products, :has_many => [ :comments, :sales ], :has_one => :seller
  
  # Sample resource route with more complex sub-resources
  #   map.resources :products do |products|
  #     products.resources :comments
  #     products.resources :sales, :collection => { :recent => :get }
  #   end

  # Sample resource route within a namespace:
  #   map.namespace :admin do |admin|
  #     # Directs /admin/products/* to Admin::ProductsController (app/controllers/admin/products_controller.rb)
  #     admin.resources :products
  #   end

  # You can have the root of your site routed with map.root -- just remember to delete public/index.html.
  # map.root :controller => "welcome"

  # See how all your routes lay out with "rake routes"

  # Install the default routes as the lowest priority.
  map.root :controller => "checkmark"
  map.connect 'checkmark', :controller => 'checkmark'
  map.connect 'checkmark/login', :controller => 'checkmark', :action => 'login'
  map.connect 'checkmark/logout', :controller => 'checkmark', :action => 'logout'

  map.connect 'checkmark/tas', :controller => 'tas'
  map.connect 'checkmark/ta_assignments', :controller => 'ta_assignments'
  
  # map filenames to a nice-looking url
  #map.connect 'checkmark/submissions/view/:id/:filename', 
  #  :controller => 'submissions', :action => 'view', :id => /\d+/, :filename => /\w+.\w+/

  map.connect 'checkmark/users/:role/:action/:id', :controller => 'users'

  # append xml to the classlist link
  map.connect 'checkmark/users/:role/userlist.:format', :controller => 'users', :action =>      'userlist'
  
  map.connect 'checkmark/:controller/:action/:id'

  # map.connect ':controller/:action/:id'
  # map.connect ':controller/:action/:id.:format'
  map.connect 'checkmark/annotations/grader/:aid/:uid', :controller => 'annotations', :action => 'grader'

end
