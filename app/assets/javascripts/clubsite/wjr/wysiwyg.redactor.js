/*jslint browser: true indent: 2*/

// NOTE: Requires the redactor library ($.fn.redactor), which is not part of
// this bundle (it was injected at deploy time in the original clubsite app).
window.WJR = window.WJR || {};
WJR.wysiwyg = (function ($) {
  'use strict';
  var wysiwyg = {};
  wysiwyg.updateTextareas = function () { return; };
  wysiwyg.createRichTextArea = function (element) {
    // Degrade to a plain textarea when the redactor library isn't mounted;
    // without this guard every page with a rich-text area throws on load.
    if ($.fn.redactor === undefined) {
      return;
    }
    $(element).redactor({
      toolbarFixed: true,
      toolbarFixedBox: true,
      imageUpload: '/api/redactor/uploadImage.json',
      fileUpload: '/api/redactor/uploadFile.json'
    });
  };

  return wysiwyg;
}(jQuery));
