/*jslint browser: true indent: 2*/

// NOTE: Requires the redactor library ($.fn.redactor), which is not part of
// this bundle (it was injected at deploy time in the original clubsite app).
window.WJR = window.WJR || {};
WJR.wysiwyg = (function ($) {
  'use strict';
  var wysiwyg = {};
  wysiwyg.updateTextareas = function () { return; };
  wysiwyg.createRichTextArea = function (element) {
    $(element).redactor({
      toolbarFixed: true,
      toolbarFixedBox: true,
      imageUpload: '/proxies/redactor/uploadImage',
      fileUpload: '/proxies/redactor/uploadFile'
    });
  };

  return wysiwyg;
}(jQuery));
