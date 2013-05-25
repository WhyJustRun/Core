//= require fullcalendar.min

$(window).load(function() {
    $('#full-calendar').fullCalendar({
        events: '/events.json',
        timeFormat: 'h:mmtt',
        firstDay: 1,
    });
});
