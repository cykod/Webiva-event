class Event::PageRenderer < ParagraphRenderer

  features '/event/page_feature'

  paragraph :calendar, :ajax => true
  paragraph :event_list
  paragraph :event_details

  def calendar
    @options = paragraph_options :calendar

    get_events
    
    if ajax?
      render_paragraph :text => @events.to_json(:public => true, :user => myself), :content_type => 'application/json'
      return
    end

    require_js 'http://ajax.googleapis.com/ajax/libs/jquery/1.4.2/jquery.js'
    require_js 'http://ajax.googleapis.com/ajax/libs/jqueryui/1.8.4/jquery-ui.min.js'
    require_js '/components/event/js/fullcalendar/fullcalendar.js'
    require_js '/components/event/js/calendar.js'
    require_css '/components/event/js/fullcalendar/fullcalendar.css'
    require_css 'http://ajax.googleapis.com/ajax/libs/jqueryui/1.8.11/themes/cupertino/jquery-ui.css'

    render_paragraph :feature => :event_page_calendar
  end

  def event_list
    @options = paragraph_options :event_list
    
    conn_type, conn_id = page_connection(:event)
    return render_paragraph :nothing => true if conn_type == :permalink && ! conn_id.blank? && ! editor?

    @start_date = @options.event_start_date
    scope = @options.event_scope
    conn_type, conn_id = page_connection :target
    scope = scope.for_owner(conn_id) if conn_id
    @events = scope.all
    
    render_paragraph :feature => :event_page_event_list
  end

  def event_details
    @options = paragraph_options :event_details
    @options.event_page_id = site_node.id

    if editor?
      @event = EventEvent.first
      return render_paragraph :text => 'No events found' unless @event
    else
      conn_type, conn_id = page_connection
      @event = EventEvent.where(:permalink => conn_id).first if conn_type == :permalink
    end
    
    return render_paragraph :nothing => true unless @event
    
    @booking = @event.event_bookings.where(:end_user_id => myself.id).first if myself.id
    @booking ||= @event.event_bookings.new :end_user_id => myself.id

    if request.post? && ! editor? && params[:booking]
      @booking.responded = true
      @updated = @booking.update_attributes params[:booking].slice(:email, :number, :attending)
    end

    render_paragraph :feature => :event_page_event_details
  end

  def get_events
    @month = Time.now.month.to_i
    @year = Time.now.year.to_i
    begin
      @current_month = Time.utc(@year, @month)
    rescue
      @current_month = Time.now.at_beginning_of_month
      @month = @current_month.month
      @year = @current_month.year
    end
    @from = @current_month - 1.month
    @to = (@current_month + 1.month).at_end_of_month
    @events = EventEvent.published.where(:event_at => @from..@to).order('event_at').all
  end
end
