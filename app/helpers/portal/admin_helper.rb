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

module Portal::AdminHelper
  def ssr_statuses
    arr = {}
    @service_requests.map do |s|
      ssr_status = pretty_tag(s.status).blank? ? "draft" : pretty_tag(s.status)
      if arr[ssr_status].blank?
        arr[ssr_status] = [s]
      else
        arr[ssr_status] << s
      end
    end
    arr
  end

  def full_ssr_id(ssr)
    protocol = ssr.service_request.protocol
    if protocol
      "#{protocol.id}-#{ssr.ssr_id}"
    else
      "-#{ssr.ssr_id}"
    end
  end

  def service_request_owner_display sub_service_request
    if sub_service_request.status == "draft"
      content_tag(:span, 'Not available in draft status.')
    else
      select_tag "sub_service_request_owner", owners_for_select(sub_service_request), :prompt => '---Please Select---', :'data-sub_service_request_id' => sub_service_request.id, :class => 'selectpicker'
    end
  end

  def ready_for_fulfillment_display user, sub_service_request
    display = content_tag(:div, "", class: "row")
    if sub_service_request.ready_for_fulfillment?
      if sub_service_request.in_work_fulfillment?
        display += content_tag(:h4, "In Fulfillment")
        display += content_tag(:div, "", class: "row")
        if user.clinical_provider_rights?
          display += link_to "Go to Fulfillment", CLINICAL_WORK_FULFILLMENT_URL, target: "_blank", class: "btn btn-primary btn-md"
        else
          display += check_box_tag "in_work_fulfillment", true, true, :'data-sub_service_request_id' => sub_service_request.id, class: "cwf_data form-control", disabled: true
        end
      else
        display += content_tag(:h4, "Ready for Fulfillment")
        display += content_tag(:div, "", class: "row")
        display += check_box_tag "in_work_fulfillment", true, false, :'data-sub_service_request_id' => sub_service_request.id, class: "cwf_data form-control"
      end
    else
      display += content_tag(:h4, "Not Ready for Fulfillment")
      display += content_tag(:div, "", class: "row")
      display += content_tag(:span, 'This Sub Service Request is not ready for Fulfillment.')
    end

    return display
  end
end
