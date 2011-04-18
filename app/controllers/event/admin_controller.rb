
class Event::AdminController < ModuleController

  component_info 'Event', :description => 'Event support', 
                              :access => :public
                              
  # Register a handler feature
  register_permission_category :event, "Event" ,"Permissions related to Event"
  
  register_permissions :event, [ [ :manage, 'Manage Event', 'Manage Event' ],
                                  [ :config, 'Configure Event', 'Configure Event' ]
                                  ]
  cms_admin_paths "options",
     "Event Options" => { :action => 'index' },
     "Options" => { :controller => '/options' },
     "Modules" => { :controller => '/modules' }

  permit 'event_config'

  public 
 
  def options
    cms_page_path ['Options','Modules'],"Event Options"
    
    @options = self.class.module_options(params[:options])
    
    if request.post? && @options.valid?
      Configuration.set_config_model(@options)
      flash[:notice] = "Updated Event module options".t 
      redirect_to :controller => '/modules'
      return
    end    
  
  end
  
  def self.module_options(vals=nil)
    Configuration.get_config_model(Options,vals)
  end
  
  class Options < HashModel
   # Options attributes 
   # attributes :attribute_name => value
  
  end

end
