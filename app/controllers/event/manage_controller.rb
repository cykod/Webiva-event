class Event::ManageController < ModuleController
  include ActiveTable::Controller

  permit 'event_manage'

  component_info 'Event'

  cms_admin_paths 'content',
                  'Content'  => {:controller => '/content'},
                  'Events'   => {:action => 'events'}


  # need to include
  active_table :events_table,
                EventEvent,
                [ :name,
                  hdr(:options, 'event_type_id', :options => :event_type_options),
                  :event_at
                ]

  def display_events_table(display=true)
    active_table_action 'event' do |act,ids|
    end

    @active_table_output = events_table_generate params, :order => 'event_events.event_at DESC'

    render :partial => 'events_table' if display
  end
  
  def events
    cms_page_path ['Content'], 'Events'
    display_events_table(false)
  end
  
  def event
    @event = EventEvent.find(params[:path][0]) if params[:path][0]
    @event ||= EventType.default.event_events.new :end_user_id => myself.id
    
    if request.post? && params[:event]
      if @event.update_attributes(params[:event])
        redirect_to :action => 'events'
      end
    end
    
    cms_page_path ['Content', 'Events'], 'Event'
  end

  protected
  
  def event_type_options
    EventType.select_options
  end
end
