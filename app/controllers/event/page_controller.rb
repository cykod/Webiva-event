class Event::PageController < ParagraphController

  editor_header 'Event Paragraphs'
  
  editor_for :calendar, :name => "Calendar", :feature => :event_page_calendar
  editor_for :event_list, :name => "Event list", :feature => :event_page_event_list

  user_actions :events

  class CalendarOptions < HashModel
    # Paragraph Options
    # attributes :success_page_id => nil

    options_form(
                 # fld(:success_page_id, :page_selector) # <attribute>, <form element>, <options>
                 )
  end

  class EventListOptions < HashModel
    # Paragraph Options
    # attributes :success_page_id => nil

    options_form(
                 # fld(:success_page_id, :page_selector) # <attribute>, <form element>, <options>
                 )
  end

  def events
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
    render :json => @events.as_json(:public => true), :content_type => 'application/json'
  end
end
