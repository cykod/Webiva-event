
class Event::AdminController < ModuleController

  component_info 'Event', :description => 'Event support', :access => :public
                              
  # Register a handler feature
  register_permission_category :event, "Event" ,"Permissions related to Event"
  
  register_permissions :event, [[:manage, 'Manage Event', 'Manage Event'],
                                [:config, 'Configure Event', 'Configure Event']
                               ]

  cms_admin_paths "options",
     "Event Options" => { :action => 'index' },
     "Options" => { :controller => '/options' },
     "Modules" => { :controller => '/modules' }

  permit 'event_config'

  content_model :event

  public 

  def self.get_event_info
    [ { :name => 'Events', :url => { :controller => '/event/manage', :action => 'calendar' }, :permission => :event_manage }
    ]
  end
end
