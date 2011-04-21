class Event::PageFeature < ParagraphFeature

  feature :event_page_calendar, :default_feature => <<-FEATURE
    <cms:calendar_settings/>
  FEATURE

  def event_page_calendar_feature(data)
    webiva_feature(:event_page_calendar,data) do |c|
      c.define_tag('calendar_settings') { |t| render_to_string :partial => '/event/page/calendar', :locals => {:options => data[:options], :events => data[:events], :events_url => ajax_url, :paragraph => paragraph} }
    end
  end

  feature :event_page_event_list, :default_feature => <<-FEATURE
    Event list Feature Code...
  FEATURE

  def event_page_event_list_feature(data)
    webiva_feature(:event_page_event_list,data) do |c|
      # c.define_tag ...
    end
  end
end
