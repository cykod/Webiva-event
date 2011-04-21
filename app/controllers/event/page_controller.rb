class Event::PageController < ParagraphController

  editor_header 'Event Paragraphs'
  
  editor_for :calendar, :name => "Calendar", :feature => :event_page_calendar
  editor_for :event_list, :name => "Event list", :feature => :event_page_event_list

  class CalendarOptions < HashModel
    # Paragraph Options
    # attributes :success_page_id => nil

    options_form(
                 # fld(:success_page_id, :page_selector) # <attribute>, <form element>, <options>
                 )
  end

  class EventListOptions < HashModel
    attributes :event_type_id => nil, :relative_date_start => 'now', :relative_date_end => '1'

    options_form(
                 fld(:event_type_id, :select, :options => :event_type_options),
                 fld(:relative_date_start, :select, :options => :relative_date_start_options, :label => "Display events from"),
                 fld(:relative_date_end, :select, :options => :relative_date_end_options, :label => "Display events to")
                 )
    
    def event_type_options
      [['--All event types--', nil]] + EventType.select_options
    end
    
    def relative_date_start_options
      Content::Field.relative_date_start_options
    end

    def relative_date_end_options
      Content::Field.relative_date_end_options
    end
    
    def event_start_date
      @event_start_date ||= Content::Field.calculate_filter_start_date self.relative_date_start
    end

    def event_end_date
      @event_end_date ||= Content::Field.calculate_filter_end_date self.event_start_date, self.relative_date_end
    end
    
    def event_range
      self.event_start_date..self.event_end_date
    end
    
    def event_scope
      scope = EventEvent.published.where(:event_at => self.event_range).order('event_at')
      scope = scope.where(:event_type_id => self.event_type_id) if self.event_type_id
      scope
    end
    
    def events(opts={})
      self.event_scope.all
    end
  end
end
