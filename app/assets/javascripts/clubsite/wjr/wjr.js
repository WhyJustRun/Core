/*jslint browser: true indent: 2*/

window.WJR = window.WJR || {};
WJR.wjr = (function ($) {
  'use strict';
  var wjr = {};
  wjr.core = {};
  wjr.core.domain = $('meta[name="wjr.core.domain"]').attr("content");

  $.ajaxSetup({
    beforeSend: function (xhr, settings) {
      if (!/^(GET|HEAD|OPTIONS|TRACE)$/i.test(settings.type)) {
        var token = $('meta[name="csrf-token"]').attr('content');
        if (token) {
          xhr.setRequestHeader('X-CSRF-Token', token);
        }
      }
    }
  });

  return wjr;
}(jQuery));
