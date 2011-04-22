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
  
 feature :event_page_event_details, :default_feature => <<-FEATURE
 <cms:event>
    <h2><cms:name/></h2>
    <p><cms:description/></p>
    <cms:updated>
      Thank you for your response.
    </cms:updated>
    <cms:not_updated>
      <cms:form>
      <ul>
        <cms:not_logged_in>
          <li><cms:name_label/> <cms:name/></li>
          <li><cms:email_label/> <cms:email/></li>
        </cms:not_logged_in>
        <cms:logged_in>
          <cms:booking>
          <cms:responded>
            <li><cms:name/>, do you need to change your response?</li>
          </cms:responded>
          <cms:not_responded>
            <li><cms:name/>, will you be attending this event?</li>
          </cms:not_responded>
          </cms:booking>
        </cms:logged_in>
        <li><cms:attending_label/> <cms:attending/></li>
        <cms:allow_guests>
          <li><cms:number_label/> <cms:number/></li>
        </cms:allow_guests>
        <li><label>&nbsp;</label> <cms:submit/></li>
      </ul>
      </cms:form>
    </cms:not_updated>
  <cms:bookings>
    <div>Attendees</div>
    <ul>
    <cms:booking>
      <li><cms:name/>
          <cms:attending>
            yes
            <cms:has_guests>+<cms:guests/> guests</cms:has_guests>
          </cms:attending>
          <cms:not_attending>no</cms:not_attending>
      </li>
    </cms:booking>
    </ul>
  </cms:bookings>
  </cms:event>
  FEATURE

  def event_page_event_details_feature(data)
    webiva_feature(:event_page_event_details,data) do |c|
      c.expansion_tag('logged_in') { |t| myself.id }
      c.expansion_tag('updated') { |t| data[:updated] }
      c.expansion_tag('event') { |t| t.locals.event = data[:event] }
      self.event_features c, data
      self.booking_form_feature c, data
      c.loop_tag('event:booking') { |t| t.locals.event.attendance }
      c.booking_features c, data, 'booking'
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
    c.expansion_tag("#{base}:ended") { |t| t.locals.event.ended? }
    c.expansion_tag("#{base}:started") { |t| t.locals.event.started? }
    c.expansion_tag("#{base}:allow_guests") { |t| t.locals.event.allow_guests }
  end
  
  def booking_form_feature(c, data, base='event')
    c.form_for_tag("#{base}:form", 'booking') { |t| t.locals.booking = data[:booking] }
    c.field_tag("#{base}:form:email")
    c.field_tag("#{base}:form:name")
    c.field_tag("#{base}:form:number", :control => 'select', :options => (1..5).to_a, :label => "Number attending")
    c.field_tag("#{base}:form:attending", :control => 'yes_no')
    c.button_tag("#{base}:form:submit")
    c.expansion_tag("#{base}:form:booking") { |t| t.locals.booking }
    c.booking_features c, data, "#{base}:form:booking"
  end
  
  def booking_features(c, data, base='booking')
    c.h_tag("#{base}:name") { |t| t.locals.booking.name }
    c.expansion_tag("#{base}:attending") { |t| t.locals.booking.attending }
    c.expansion_tag("#{base}:responded") { |t| t.locals.booking.responded }
    c.expansion_tag("#{base}:has_guests") { |t| t.locals.booking.number > 1 }
    c.value_tag("#{base}:number") { |t| t.locals.booking.number }
    c.value_tag("#{base}:guests") { |t| t.locals.booking.number - 1 }
  end
end
