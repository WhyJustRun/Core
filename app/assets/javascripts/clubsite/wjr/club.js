 /*jslint browser: true indent: 2*/

 window.WJR = window.WJR || {};
 WJR.club = (function ($) {
   var club = {};
   club.id = $('meta[name="wjr.clubsite.club.id"]').attr("content");
   return club;
 }(jQuery));
