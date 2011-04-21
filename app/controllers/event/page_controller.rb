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
    # Paragraph Options
    # attributes :success_page_id => nil

    options_form(
                 # fld(:success_page_id, :page_selector) # <attribute>, <form element>, <options>
                 )
  end
end
