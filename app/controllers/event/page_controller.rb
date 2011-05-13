class Event::PageController < ParagraphController

  editor_header 'Event Paragraphs'
  
  editor_for :calendar, :name => "Calendar", :feature => :event_page_calendar, :inputs => {
    :target => [[:target, 'Target', :target],
                [:content, 'Content', :content]],
    :event => [[:permalink, 'Event Url', :path]]
  }
  editor_for :event_list, :name => "Event List", :feature => :event_page_event_list, :inputs => {
    :target => [[:target, 'Target', :target],
                [:content, 'Content', :content]],
    :event => [[:permalink, 'Event Url', :path]],
    :post_permission => [[:target, 'Create Permission Target', :target],
                         [:content, 'Create Permission Content', :content]]

  }
  editor_for :event_details, :name => "Event Details", :feature => :event_page_event_details,
  :inputs => {
    :input => [[:permalink, 'Event Url', :path]],
    :book_permission => [[:target, 'Book Permission Target', :target],
                         [:content, 'Book Permission Content', :content]]
  },
  :outputs => [[:event, 'Event Content', :content],
               [:event_id, 'Event Identifier', :event_id]]
  editor_for :create_event, :name => "Create Event", :feature => :event_page_create_event, :inputs => {
    :input => [[:permalink, 'Event Url', :path]],
    :owner => [[:target, 'Event Owner Target', :target],
               [:content, 'Event Owner Content', :content]],
    :post_permission => [[:target, 'Create Permission Target', :target],
                         [:content, 'Create Permission Content', :content]],
    :admin_permission => [[:target, 'Admin Permission Target', :target],
                          [:content, 'Admin Permission Content', :content]]
  }
  
  class CalendarOptions < HashModel
    attributes :calendar_page_id => nil, :list_page_id => nil, :details_page_id => nil, :create_page_id => nil, :event_type_id => nil

    page_options :calendar_page_id, :list_page_id, :details_page_id, :create_page_id

    options_form(
                 fld(:event_list_id, :page_selector),
                 fld(:details_page_id, :page_selector),
                 fld(:create_page_id, :page_selector),
                 fld(:event_type_id, :select, :options => :event_type_options)
                 )

    def event_type_options
      [['--All event types--', nil]] + EventType.select_options
    end

    def event_range
      current_month = Time.now.at_beginning_of_month
      from = current_month - 1.month
      to = (current_month + 1.month).at_end_of_month
      from..to
    end

    def event_scope
      scope = EventEvent.where(:event_at => self.event_range).order('event_at')
      scope = scope.where(:event_type_id => self.event_type_id) if self.event_type_id
      scope
    end
    
    def event_type
      @event_type ||= EventType.where(:id => self.event_type_id).first
    end
  end

  class EventListOptions < HashModel
    attributes :calendar_page_id => nil, :list_page_id => nil, :details_page_id => nil, :create_page_id => nil, :event_type_id => nil, :relative_date_start => 'now', :relative_date_end => '1',:show_other => false

    page_options :calendar_page_id, :list_page_id, :details_page_id, :create_page_id
    boolean_options :show_other

    options_form(
                 fld(:calendar_page_id, :page_selector),
                 fld(:create_page_id, :page_selector),
                 fld(:details_page_id, :page_selector),
                 fld(:event_type_id, :select, :options => :event_type_options),
                 fld(:relative_date_start, :select, :options => :relative_date_start_options, :label => "Display events from"),
                 fld(:relative_date_end, :select, :options => :relative_date_end_options, :label => "Display events to"),
                 fld(:show_other,:yes_no,:label => 'Display all non-targeted events')
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
      scope = EventEvent.where(:event_at => self.event_range).order('event_at')
      scope = scope.where(:event_type_id => self.event_type_id) if self.event_type_id
      scope
    end

    def event_type
      @event_type ||= EventType.where(:id => self.event_type_id).first
    end
  end
  
  class EventDetailsOptions < HashModel
    attributes :calendar_page_id => nil, :list_page_id => nil, :details_page_id => nil, :create_page_id => nil, :event_type_id => 1
    
    page_options :calendar_page_id, :list_page_id, :details_page_id, :create_page_id

    options_form(
                 fld(:calendar_page_id, :page_selector),
                 fld(:list_page_id, :page_selector),
                 fld(:create_page_id, :page_selector),
                 fld(:event_type_id, :select, :options => :event_type_options)
                 )

    def event_type_options
      [['--All event types--', nil]] + EventType.select_options_with_nil
    end

    def event_type
      @event_type ||= EventType.where(:id => self.event_type_id).first
    end
  end

  class CreateEventOptions < HashModel
    attributes :calendar_page_id => nil, :list_page_id => nil, :details_page_id => nil, :create_page_id => nil, :event_type_id => 1
    
    page_options :calendar_page_id, :list_page_id, :details_page_id, :create_page_id
    
    validates_presence_of :event_type_id

    options_form(
                 fld(:calendar_page_id, :page_selector),
                 fld(:list_page_id, :page_selector),
                 fld(:details_page_id, :page_selector),
                 fld(:event_type_id, :select, :options => :event_type_options)
                 )
    
    def event_type_options
      EventType.select_options_with_nil
    end

    def event_type
      @event_type ||= EventType.where(:id => self.event_type_id).first
    end
  end
end
