class Event::ManageController < ModuleController
  include ActiveTable::Controller
  
  permit 'event_manage'

  component_info 'Event'

  cms_admin_paths 'content',
                  'Content'  => {:controller => '/content'},
                  'Events'   => {:action => 'events'},
                  'Events Calendar'   => {:action => 'calendar'}


  # need to include
  active_table :events_table,
                EventEvent,
                [ :name,
                  hdr(:options, 'event_type_id', :options => :event_type_options),
                  :event_at,
                  hdr(:static, 'Ends at')
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
    @event ||= EventType.default.build_event :end_user_id => myself.id, :duration => 1440
    if params[:date]
      date = Time.at params[:date].to_i
      @event.event_on = date
    end

    if request.post? && params[:event]
      if @event.update_attributes(params[:event])
        if request.xhr?
          render :update do |page|
            page << "$j('#calendar').fullCalendar('refetchEvents');"
          end
        else
          redirect_to :action => 'events'
        end
        return
      end
    end
    
    return render :partial => 'event' if request.xhr?
    
    cms_page_path ['Content', 'Events'], 'Event'
  end

  def calendar
    get_calendar_events

    cms_page_path ['Content', 'Events'], 'Events Calendar'
    
    require_js '/components/event/js/fullcalendar/fullcalendar.js'
    require_js '/components/event/js/calendar.js'
    require_css '/components/event/js/fullcalendar/fullcalendar.css'
    require_css '/components/event/js/fullcalendar/fullcalendar.print.css'
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
    render :json => {:moved => true}, :content_type => 'application/json'
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
