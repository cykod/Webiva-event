class Event::PageFeature < ParagraphFeature

  feature :event_page_calendar, :default_feature => <<-FEATURE
  <cms:calendar/>
  FEATURE

  def event_page_calendar_feature(data)
    webiva_feature(:event_page_calendar,data) do |c|
      c.define_tag('calendar') { |t| render_to_string :partial => '/event/page/calendar', :locals => {:options => data[:options], :events => data[:events], :events_url => ajax_url, :paragraph => paragraph} }
    end
  end

  feature :event_page_event_list, :default_feature => <<-FEATURE
  <cms:events>
  <ul>
    <cms:event>
    <li><cms:name/> on <cms:event_at/><br/><cms:description/></li>
    </cms:event>
  </ul>
  </cms:events>
  FEATURE

  def event_page_event_list_feature(data)
    webiva_feature(:event_page_event_list,data) do |c|
      c.date_tag("start_date", DEFAULT_DATETIME_FORMAT.t) { |t| data[:start_date] }
      c.loop_tag('event') { |t| data[:events] }
      self.event_features c, data
    end
  end
  
  def event_features(c, data, base='event')
    c.h_tag("#{base}:name") { |t| t.locals.event.name }
    c.h_tag("#{base}:description") { |t| t.locals.event.description }
    c.h_tag("#{base}:address") { |t| t.locals.event.address }
    c.h_tag("#{base}:address_2") { |t| t.locals.event.address_2 }
    c.h_tag("#{base}:city") { |t| t.locals.event.city }
    c.h_tag("#{base}:state") { |t| t.locals.event.state }
    c.h_tag("#{base}:zip") { |t| t.locals.event.zip }
    c.value_tag("#{base}:lon") { |t| t.locals.event.lon }
    c.value_tag("#{base}:lat") { |t| t.locals.event.lat }
    c.image_tag("#{base}:image") { |t| t.locals.event.image }
    c.date_tag("#{base}:event_at", DEFAULT_DATETIME_FORMAT.t) { |t| t.locals.event.event_at }
    c.date_tag("#{base}:ends_at", DEFAULT_DATETIME_FORMAT.t) { |t| t.locals.event.ends_at }
    c.value_tag("#{base}:spaces") { |t| t.locals.event.spaces }
    c.value_tag("#{base}:bookings") { |t| t.locals.event.bookings }
    c.value_tag("#{base}:unconfirmed_bookings") { |t| t.locals.event.unconfirmed_bookings }
  end
end
