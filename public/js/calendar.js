EventCalendar = {
  events: null,
  updateUrl: null,
  addEventUrl: null,

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

  init: function(element_id, events) {
    EventCalendar.events = events;

    $j('#' + element_id).fullCalendar({
	header: {
	  left: 'prev,next today',
	  center: 'title',
	  right: 'month,agendaWeek,agendaDay'
	},
	editable: true,
	events: EventCalendar.loadEvents,
	dayClick: EventCalendar.addEvent,
	eventClick: EventCalendar.editEvent,
        loading: function(isLoading, view) { if(isLoading) { RedBox.loading(); } else { RedBox.close(); } },
	eventDrop: function(event, delta) {
	  alert(event.title + ' was moved ' + delta + ' days\n' +
		'(should probably update your database)');
	}
      });
  }
}
