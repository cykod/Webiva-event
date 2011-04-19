EventCalendar = {
  calendar: null,
  events: null,
  updateUrl: null,
  addEventUrl: null,
  moveEventUrl: null,
  deleteEventUrl: null,

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
    $j.getJSON(EventCalendar.moveEventUrl + "/" + event.event_id, {days: dayDelta, minutes: minuteDelta, allDay: allDay, duration: 0}, function(data) {
	if(data.moved == false) {
          revertFunc();
	} else {
	  EventCalendar.updateEvent(event, data);
        }
      });
  },

  resizeEvent: function(event, dayDelta, minuteDelta, revertFunc, jsEvent, ui, view) {
    var duration = dayDelta * 24 * 60 + minuteDelta;
    $j.getJSON(EventCalendar.moveEventUrl + "/" + event.event_id, {days: 0, minutes: 0, allDay: false, duration: duration}, function(data) {
	if(data.moved == false) {
          revertFunc();
	} else {
	  EventCalendar.updateEvent(event, data);
        }
      });
  },

  updateEvent: function(event, data) {
    event.start = data.event.start;
    event.end = data.event.end;
    event.allDay = data.event.allDay;
    EventCalendar.calendar.fullCalendar('updateEvent', event);
  },

  refresh: function() {
    EventCalendar.calendar.fullCalendar('refetchEvents');
  },

  deleteEvent: function(event_id) {
    $j.post(EventCalendar.deleteEventUrl + "/" + event_id);
  },

  selectRanage: function(startDate, endDate, allDay, jsEvent, view) {
    SCMS.remoteOverlay(EventCalendar.addEventUrl, {start: startDate.getTime() / 1000, end: endDate.getTime() / 1000, allDay: allDay});
  },

  init: function(element_id, events, month, year) {
    EventCalendar.events = events;
    EventCalendar.calendar = $j('#' + element_id);
    
    EventCalendar.calendar.fullCalendar({
	theme: true,
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
        eventDrop: EventCalendar.moveEvent,
	eventResize: EventCalendar.resizeEvent,
	selectable: true,
	select: EventCalendar.selectRanage
      });
  }
}
