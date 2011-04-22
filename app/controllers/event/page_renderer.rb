class Event::PageRenderer < ParagraphRenderer

  features '/event/page_feature'

  paragraph :calendar, :ajax => true
  paragraph :event_list
  paragraph :event_details
  paragraph :create_event

  def calendar
    @options = paragraph_options :calendar
    @options.calendar_page_id = site_node.id
    
    scope = @options.event_scope
    conn_type, conn_id = page_connection :target
    scope = scope.for_owner(conn_id) if conn_id
    @events = scope.all
    
    if ajax?
      render_paragraph :text => @events.to_json(:public => true, :user => myself, :event_node => @options.details_page_node), :content_type => 'application/json'
      return
    end

    conn_type, conn_id = page_connection(:event)
    return render_paragraph :nothing => true if conn_type == :permalink && ! conn_id.blank? && ! editor?

    unless editor?
      require_js 'http://ajax.googleapis.com/ajax/libs/jquery/1.4.2/jquery.js'
      require_js 'http://ajax.googleapis.com/ajax/libs/jqueryui/1.8.4/jquery-ui.min.js'
      require_js '/components/event/js/fullcalendar/fullcalendar.js'
      require_js '/components/event/js/calendar.js'
      require_css '/components/event/js/fullcalendar/fullcalendar.css'
      require_css 'http://ajax.googleapis.com/ajax/libs/jqueryui/1.8.11/themes/cupertino/jquery-ui.css'
    end

    return render_paragraph :text => '[Display Full Calendar]' if editor?

    render_paragraph :feature => :event_page_calendar
  end

  def event_list
    @options = paragraph_options :event_list
    @options.list_page_id = site_node.id
    
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
    @options.details_page_id = site_node.id

    if editor?
      @event = EventEvent.first
      return render_paragraph :text => 'No events found' unless @event
    else
      conn_type, conn_id = page_connection
      @event = EventEvent.where(:permalink => conn_id).first if conn_type == :permalink
    end
    
    return render_paragraph :nothing => true unless @event
    
    conn_type, conn_id = page_connection :book_permission
    
    if conn_id || editor?
      @booking = @event.event_bookings.where(:end_user_id => myself.id).first if myself.id
      @booking ||= @event.event_bookings.new :end_user_id => myself.id

      if request.post? && ! editor? && params[:booking]
        @booking.responded = true
        @updated = @booking.update_attributes params[:booking].slice(:email, :name, :number, :attending)
      end
    end

    render_paragraph :feature => :event_page_event_details
  end
  
  def create_event
    @options = paragraph_options :create_event
    @options.create_page_id = site_node.id

    # must be logged in
    return render_paragraph :nothing => true unless myself.id
    
    # must have permission to create an event
    unless editor?
      conn_type, @post_permission = page_connection :post_permission
      conn_type, @admin_permission = page_connection :admin_permission
      return render_paragraph :nothing => true unless @post_permission || @admin_permission
    end

    conn_type, @owner = page_connection :owner
    @owner ||= myself
    
    conn_type, conn_id = page_connection
    if conn_type == :permalink
      if ! conn_id.blank?
        @event = EventEvent.for_owner(@owner).where(:permalink => conn_id).first
        @event = nil if @event && @event.end_user_id != myself.id && ! @admin_permission
      else
        @event = EventEvent.new :event_type_id => @options.event_type_id, :owner_type => @owner.class.to_s.underscore, :owner_id => @owner.id, :duration => 120
      end
    elsif editor?
      @event = EventEvent.new :event_type_id => EventType.default.id, :owner_type => @owner.class.to_s.underscore, :owner_id => @owner.id, :duration => 120
    end

    raise SiteNodeEngine::MissingPageException.new(site_node, language) unless @event

    if request.post? && ! editor? && params[:event]
      if @event.update_attributes params[:event].slice(:name, :description, :event_on, :start_time)
        if @options.details_page_node
          redirect_paragraph @options.details_page_node.link(@event.permalink)
          return
        end
        @updated = true
      end
    end
    
    render_paragraph :feature => :event_page_create_event
  end
end
