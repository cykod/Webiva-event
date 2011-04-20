class Event::PageRenderer < ParagraphRenderer

  features '/event/page_feature'

  paragraph :calendar
  paragraph :event_list

  def calendar
    @options = paragraph_options :calendar

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

    render_paragraph :feature => :event_page_event_list
  end
end
