//= require fullcalendar.min

$(window).load(function() {
    $('#full-calendar').fullCalendar({
        events: '/events.json?prefix_club_acronym=true',
        timeFormat: 'h:mmtt',
        firstDay: 1,
    });
});
