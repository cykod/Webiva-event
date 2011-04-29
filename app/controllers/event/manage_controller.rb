class Event::ManageController < ModuleController
  include ActiveTable::Controller
  
  permit 'event_manage'

  component_info 'Event'

  cms_admin_paths 'content',
                  'Content'  => {:controller => '/content'},
                  'Events'   => {:action => 'events'},
                  'Event Types'   => {:action => 'event_types'},
                  'Calendar'   => {:action => 'calendar'}

  active_table :events_table,
                EventEvent,
                [ :check,
                  :name,
                  hdr(:options, 'event_type_id', :options => :event_type_options),
                  :published,
                  :event_at,
                  hdr(:static, 'Ends at')
                ]

  def display_events_table(display=true)
    active_table_action 'event' do |act,ids|
      case act
      when 'delete'
        EventEvent.destroy ids
      end
    end

    @active_table_output = events_table_generate params, :order => 'event_events.event_at DESC'

    render :partial => 'events_table' if display
  end
  
  def events
    cms_page_path ['Content', 'Calendar'], 'Events'
    display_events_table(false)
  end
  
  def event
    @event = EventEvent.find(params[:path][0]) if params[:path][0]
    @event ||= EventType.default.event_events.new :end_user_id => myself.id, :duration => 1440
    if @event.id.nil? && params[:start] && params[:end]
      @event.starts_at = params[:start].to_i
      @event.ends_at = params[:end].to_i
      @event.start_time = params[:allDay] == 'true' ? nil : 0
      @event.set_event_at
    end

    if request.post? && params[:event]
      @event.attributes = params[:event]
      if params[:commit] && @event.save
        if request.xhr?
          render :update do |page|
            page << "EventCalendar.refresh();"
          end
        else
          redirect_to :action => 'calendar'
        end
        return
      end
    end
    
    return render :partial => 'event' if request.xhr?

    cms_page_path ['Content', 'Calendar', 'Events'], 'Event'
  end

  def calendar
    get_calendar_events

    cms_page_path ['Content'], 'Calendar'
    
    require_js '/components/event/js/fullcalendar/fullcalendar.js'
    require_js '/components/event/js/calendar.js'
    require_css '/components/event/js/fullcalendar/fullcalendar.css'
    require_css 'http://ajax.googleapis.com/ajax/libs/jqueryui/1.8.11/themes/cupertino/jquery-ui.css'
  end

  def calendar_events
    return render :nothing => true unless params[:end] && params[:start]
    @from = Time.at(params[:start].to_i).at_beginning_of_day
    @to = Time.at params[:end].to_i
    @events = EventEvent.where(:event_at => @from..@to).order('event_at').all
    render :json => @events, :content_type => 'application/json'
  end

  def move_event
    return render :json => {:moved => false}, :content_type => 'application/json' unless params[:path][0] && params[:days] && params[:minutes]
    days = params[:days].to_i
    minutes = params[:minutes].to_i
    all_day = params[:allDay] == 'true'
    @event = EventEvent.find params[:path][0]
    @event.move days, minutes, all_day
    render :json => {:moved => true, :event => @event}, :content_type => 'application/json'
  end

  def resize_event
    return render :json => {:moved => false}, :content_type => 'application/json' unless params[:path][0] && params[:days] && params[:minutes]
    days = params[:days].to_i
    minutes = params[:minutes].to_i
    @event = EventEvent.find params[:path][0]
    @event.resize days, minutes
    render :json => {:moved => true, :event => @event}, :content_type => 'application/json'
  end

  def delete_event
    @event = EventEvent.find params[:path][0]
    @event.destroy
    if request.xhr?
      render :update do |page|
        page << "EventCalendar.refresh();"
      end
      return
    end

    redirect_to :action => 'calendar'
  end

  active_table :event_types_table,
                EventType,
                [ :check,
                  :name,
                  :description,
                  :created_at,
                  :updated_at
                ]

  def display_event_types_table(display=true)
    active_table_action 'type' do |act,ids|
      case act
      when 'delete'
        EventType.destroy ids
      end
    end

    @active_table_output = event_types_table_generate params, :order => 'event_types.created_at DESC'

    render :partial => 'event_types_table' if display
  end
  
  def event_types
    display_event_types_table(false)
    cms_page_path ['Content', 'Calendar'], 'Event Types'
  end
  
  def event_type
    @event_type = EventType.find(params[:path][0]) if params[:path][0]
    @event_type ||= EventType.new

    if request.post? && params[:event_type]
      if @event_type.update_attributes(params[:event_type])
        redirect_to :action => 'event_types'
      end
    end
    
    cms_page_path ['Content', 'Calendar'], 'Event Types'
  end

  protected
  
  def get_calendar_events
    @month = (params[:path][0] || Time.now.month).to_i
    @year = (params[:path][1] || Time.now.year).to_i
    begin
      @current_month = Time.utc(@year, @month)
    rescue
      @current_month = Time.now.at_beginning_of_month
      @month = @current_month.month
      @year = @current_month.year
    end
    @from = @current_month - 1.month
    @to = (@current_month + 1.month).at_end_of_month
    @events = EventEvent.where(:event_at => @from..@to).order('event_at').all
  end

  def event_type_options
    EventType.select_options
  end
end
