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

require 'rails_helper'

RSpec.describe Portal::VisitsController do
  stub_portal_controller

  let!(:institution) { create(:institution) }
  let!(:provider) { create(:provider, parent_id: institution.id) }
  let!(:program) { create(:program, parent_id: provider.id) }
  let!(:core) { create(:core, parent_id: program.id) }

  let!(:service) {
    service = create(
        :service,
        organization: core,
        pricing_map_count: 1)
    service.pricing_maps[0].display_date = Date.today
    service
  }

  let!(:project) { project = Protocol.create(attributes_for(:protocol)); project.save!(validate: false); project }
  let!(:service_request) { service_request = ServiceRequest.create(attributes_for(:service_request, protocol_id: project.id)); service_request.save!(validate: false); service_request }
  let!(:arm) { create(:arm, protocol_id: project.id, visit_count: 0, subject_count: 1) }

  let!(:ssr) {
    create(
        :sub_service_request,
        service_request_id: service_request.id,
        organization_id: core.id)
  }

  let!(:subsidy) {
    create(
        :subsidy,
        sub_service_request_id: ssr.id)
  }

  describe 'POST update_from_fulfillment' do
    # TODO
  end

  describe 'destroy' do
    context 'we have one line item' do
      let!(:line_item) {
        create(
            :line_item,
            service_id: service.id,
            service_request_id: service_request.id,
            sub_service_request_id: ssr.id)
      }

      let!(:visit) {
        arm.update_attributes(visit_count: 1)
        arm.create_line_items_visit(line_item)
        visit = arm.visits[0]
      }

      it 'should set instance variables' do
        post :destroy, {
          format: :js,
          id: visit.id,
        }.with_indifferent_access
        expect(assigns(:visit)).to eq visit
        expect(assigns(:sub_service_request)).to eq ssr
        expect(assigns(:service_request)).to eq service_request
        expect(assigns(:subsidy)).to eq subsidy
        expect(assigns(:candidate_per_patient_per_visit)).to eq [ service ]
      end

      it 'should destroy the visit' do
        post :destroy, {
          format: :js,
          id: visit.id,
        }.with_indifferent_access
        expect { visit.reload }.to raise_exception(ActiveRecord::RecordNotFound)
      end

      it 'should fix the pi contribution on the subsidy' do
        allow_any_instance_of(Subsidy).to receive(:fix_pi_contribution) {
          subsidy.update_attributes(pi_contribution: 12)
        }

        post :destroy, {
          format: :js,
          id: visit.id,
        }.with_indifferent_access
        subsidy.reload
        expect(subsidy.pi_contribution).to eq 12
      end
    end

    context 'we have multiple line items' do
      let!(:line_item1) {
        create(
            :line_item,
            service_id: service.id,
            service_request_id: service_request.id,
            sub_service_request_id: ssr.id)
      }

      let!(:line_item2) {
        create(
            :line_item,
            service_id: service.id,
            service_request_id: service_request.id,
            sub_service_request_id: ssr.id)
      }

      let!(:line_item3) {
        create(
            :line_item,
            service_id: service.id,
            service_request_id: service_request.id,
            sub_service_request_id: ssr.id)
      }

      it 'should destroy all the other visits at the same position' do
        arm.update_attributes(visit_count: 10)
        arm.create_line_items_visit(line_item1)
        arm.create_line_items_visit(line_item2)
        arm.create_line_items_visit(line_item3)

        visit = arm.visits[0]
        visits = arm.visit_groups.find_by_position(visit.position).visits

        post :destroy, {
          format: :js,
          id: visit.id,
        }.with_indifferent_access

        # Reloading deleted visits should result in an exception
        visits.each do |v|
          expect { v.reload }.to raise_exception(ActiveRecord::RecordNotFound)
          expect { v.reload }.to raise_exception(ActiveRecord::RecordNotFound)
          expect { v.reload }.to raise_exception(ActiveRecord::RecordNotFound)
        end

        expect(LineItemsVisit.for(arm, line_item1).visits.count).to eq 9
        expect(LineItemsVisit.for(arm, line_item2).visits.count).to eq 9
        expect(LineItemsVisit.for(arm, line_item3).visits.count).to eq 9
      end

      it 'should update visit count' do
        arm.update_attributes(visit_count: 10)
        arm.create_line_items_visit(line_item1)
        arm.create_line_items_visit(line_item2)
        arm.create_line_items_visit(line_item3)

        visit = arm.visits[0]
        visits = arm.visit_groups.find_by_position(visit.position).visits

        post :destroy, {
          format: :js,
          id: visit.id,
        }.with_indifferent_access

        arm.reload
        expect(arm.visit_count).to eq 9
      end
    end
  end
end
