/*jslint browser: true, indent: 2, nomen: true*/

window.WJR = window.WJR || {};
WJR.clubsite = (function ($, _, moment, forms, editable) {
  'use strict';
  var Clubsite = {};

  Clubsite.initialize = function () {
    // Components that we initialize conditionally if needed for the current page
    var components = [
      {
        selector: 'a.lightbox',
        load: function (lightboxes) {
          lightboxes.fancybox();
        }
      }, {
        selector: '.date-picker',
        load: function (datePickers) {
          datePickers.datetimepicker({
            pickTime: false,
            format: "YYYY-MM-DD"
          });
        }
      }, {
        selector: '.event-list',
        module: WJR['event-list'],
        loadEach: function (element, EventList) {
          var eventList = new EventList();
          eventList.initialize(element);
        }
      }, {
        selector: '.result-list',
        module: WJR['result-list'],
        loadEach: function (element, ResultList) {
          var resultList = new ResultList();
          resultList.initialize(element);
        }
      }, {
        selector: '.color-picker',
        load: function (colorPickers) {
          colorPickers.colorpicker();
        }
      }, {
        selector: '.result-editor',
        module: WJR['result-editor'],
        loadEach: function (element, ResultEditor) {
          var resultEditor = new ResultEditor();
          resultEditor.initialize(element);
        }
      }, {
        selector: '.register-others',
        module: WJR['register-others'],
        loadEach: function (element, RegisterOthers) {
          var registerOthers = new RegisterOthers();
          registerOthers.initialize(element);
        }
      }, {
        selector: '.edit-event-courses',
        module: WJR['edit-event-courses'],
        loadEach: function (element, EventCoursesEditor) {
          var editor = new EventCoursesEditor();
          editor.initialize(element);
        }
      }, {
        selector: '.edit-event-organizers',
        module: WJR['edit-event-organizers'],
        loadEach: function (element, EventOrganizersEditor) {
          var editor = new EventOrganizersEditor();
          editor.initialize(element);
        }
      }, {
        selector: '.simple-marker-map',
        module: WJR.map,
        loadEach: function (element, map) {
          var markerMap = new map.SimpleMarkerMap();
          markerMap.initialize(element);
        }
      }, {
        selector: '.draggable-marker-map',
        module: WJR.map,
        loadEach: function (element, map) {
          var markerMap = new map.DraggableMarkerMap();
          markerMap.initialize(element);
        }
      }, {
        selector: '.multi-marker-map',
        module: WJR.map,
        loadEach: function (element, map) {
          var markerMap = new map.MultiMarkerMap();
          markerMap.initialize(element);
        }
      }, {
        selector: '.simple-person-picker',
        module: WJR.forms,
        loadEach: function (element, forms) {
          var personPicker = new forms.SimplePersonPicker();
          personPicker.initialize(element);
        }
      }
    ];

    _.each(components, function (component) {
      var results = $(component.selector);
      if (results.length !== 0) {
        if (component.load !== undefined) {
          component.load(results, component.module);
        } else {
          results.each(function () {
            component.loadEach(this, component.module);
          });
        }
      }
    });

    $('time.timeago').each(function () {
      var time = moment($(this).attr('datetime'));
      $(this).html(time.fromNow());
    });

    $('input, textarea').placeholder();

    forms.validation.checkKetchupFormsAreValidOnSubmit();

    $('.wjr-wysiwyg').each(function () {
      var element = this;
      WJR.wysiwyg.createRichTextArea(element);
    });

    $("[data-toggle='tooltip']").tooltip();

    $('.wjr-calendar').each(function () {
      var element = this;
      WJR.calendar.Initialize(element);
    });

    $('.flickr-photos-container').each(function () {
      var element = this;
      WJR['flickr-photos'].Initialize(element);
    });

    editable.initialize();

    // Event editing form
    // Fix for CakePHP form security - exclude the knockout inputs
    $("#EventEditForm").submit(function () {
      $(this).find('[name ^= "ko_unique"]').attr("name", null);
    });
  };

  return Clubsite;
}(jQuery, _, moment, WJR.forms, WJR.editable));

jQuery(function () {
  'use strict';
  WJR.clubsite.initialize();
});
