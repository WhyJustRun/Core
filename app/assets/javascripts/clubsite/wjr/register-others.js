/*jslint browser: true, indent: 2*/
/*global confirm, alert*/

window.WJR = window.WJR || {};
WJR['register-others'] = (function ($, forms) {
  'use strict';
  return function () {
    this.initialize = function (element) {
      element = $(element);
      element.find('#RegisterOthersUserId').val(null);

      var options = { maintainInput: true, allowNew: true };
      forms.personPicker(element.find('#RegisterOthersUserName'), options, function (person) {
        element.find('#RegisterOthersUserId').val((person !== null) ? person.id : null);
      });

      // Registration is a POST; build and submit a form so the browser
      // follows the redirect back to the event page.
      function completeSubmit(courseId, userId) {
        var form = $('<form></form>', {
            method: 'post',
            action: '/courses/register/' + courseId + '/' + userId
          }),
          token = $('meta[name="csrf-token"]').attr('content');
        if (token) {
          form.append($('<input>', { type: 'hidden', name: 'authenticity_token', value: token }));
        }
        form.appendTo('body').submit();
      }

      element.find('#RegisterOthersSubmit').click(function () {
        var userId, courseId, userName;
        userId = element.find('#RegisterOthersUserId').val();
        courseId = element.find('#RegisterOthersCourse').val();
        if (!userId) {
          userName = element.find('#RegisterOthersUserName').val();
          if (userName) {
            if (userName.indexOf(" ") !== -1) {
              if (confirm("This registration will create a new user in the system. Are you sure " + userName + " isn't already an WhyJustRun user?")) {
                $.post('/users/add', { userName: userName }, function (data) {
                  // The endpoint responds with the new user id as JSON,
                  // which jQuery has already parsed.
                  completeSubmit(courseId, data);
                });
              } else {
                alert("Thanks! Please re-enter the participant's name and choose the matching person from the dropdown.");
              }
            } else {
              alert("Please enter the participant's full name.");
            }
          } else {
            alert("Please enter the participant name");
          }
        } else {
          completeSubmit(courseId, userId);
        }
      });
    };
  };
}(jQuery, WJR.forms));
