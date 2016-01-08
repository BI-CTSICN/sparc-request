# Copyright © 2011 MUSC Foundation for Research Development
# All rights reserved.

# Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

# 1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.

# 2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following
# disclaimer in the documentation and/or other materials provided with the distribution.

# 3. Neither the name of the copyright holder nor the names of its contributors may be used to endorse or promote products
# derived from this software without specific prior written permission.

# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING,
# BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT
# SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR
# TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

id = "<%= @protocol.id %>"
$(".protocol-information-container-#{id}").html("<%= escape_javascript(render(:partial => 'dashboard/protocols/protocol_information', :locals => {:protocol => @protocol, :user => @user, :protocol_role => @protocol_role})) %>")
$(".panel-heading[data-protocol-id='#{id}']").goTo()

# This needs to be here so it'll be loaded in the DOM upon page load.
# Dialog will not open otherwise.
# $('.new_notification_dialog').dialog({
#   autoOpen: false,
#   dialogClass: "send_notification_dialog_box",
#   title: 'Send Notification',
#   width: 700,
#   modal: true,
#   buttons: {
#     "Send": function() {
#       $('.portal_notifications:visible').slideToggle();
#       disableSubmitButton("Send", "Please wait...");
#       return $('.notification_notification_form').bind('ajax:success', function(data) {
#         enableSubmitButton("Please wait...", "Send");
#         return $('.new_notification_dialog').dialog('close');
#       }).submit();
#     },
#     "Cancel": function() {
#       $('.portal_notifications:visible').slideToggle();
#       enableSubmitButton("Please wait...", "Send");
#       return $(this).dialog('close');
#     }
#   }
# });

# var disableSubmitButton, enableSubmitButton;
#
# disableSubmitButton = function(containing_text, change_to) {
#   var button;
#   button = $("  button:contains(" + containing_text + ")");
#   return button.html("<span class='ui-button-text'>" + change_to + "</span>").attr('disabled', true).addClass('button-disabled');
# };
#
# enableSubmitButton = function(containing_text, change_to) {
#   var button;
#   button = $("  button:contains(" + containing_text + ")");
#   button.html("<span class='ui-button-text'>" + change_to + "</span>").attr('disabled', false).removeClass('button-disabled');
#   return button.attr('disabled', false);
# };

$('.selectpicker').selectpicker()
