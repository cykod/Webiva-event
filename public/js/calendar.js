EventCalendar = {
  calendar: null,
  events: null,
  updateUrl: null,
  addEventUrl: null,
  moveEventUrl: null,

  loadEvents: function(start, end, callback) {
    if(EventCalendar.events) {
      callback(EventCalendar.events);
      EventCalendar.events = null;
    } else {
      start = Math.round(start.getTime() / 1000);
      end = Math.round(end.getTime() / 1000);
      $j.getJSON(EventCalendar.updateUrl, {start: start, end: end}, function(data) { callback(data); });
    }
  },

  editEvent: function(event, jsEvent, view) {
    SCMS.remoteOverlay(EventCalendar.addEventUrl + "/" + event.event_id);
  },

  addEvent: function(date, allDay, jsEvent, view) {
    SCMS.remoteOverlay(EventCalendar.addEventUrl, {date: date.getTime() / 1000, allDay: allDay});
  },

  moveEvent: function(event, dayDelta, minuteDelta, allDay, revertFunc, jsEvent, ui, view) {
    $j.getJSON(EventCalendar.moveEventUrl + "/" + event.event_id, {days: dayDelta, minutes: minuteDelta, allDay: allDay}, function(data) {
	if(data.moved == false) {
	  EventCalendar.refresh();
	}
      });
  },

  refresh: function() {
    EventCalendar.calendar.fullCalendar('refetchEvents');
  },

  init: function(element_id, events, month, year) {
    EventCalendar.events = events;
    EventCalendar.calendar = $j('#' + element_id);
    
    EventCalendar.calendar.fullCalendar({
	header: {
	  left: 'prev,next today',
	  center: 'title',
	  right: 'month,agendaWeek,agendaDay'
	},
	editable: true,
        month: month,
        year: year,
	events: EventCalendar.loadEvents,
	dayClick: EventCalendar.addEvent,
	eventClick: EventCalendar.editEvent,
        loading: function(isLoading, view) { if(isLoading) { RedBox.loading(); } else { RedBox.close(); } },
        eventDrop: EventCalendar.moveEvent
      });
  }
}
