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

require 'spec_helper'

describe 'ServiceRequest' do

  let_there_be_lane
  let_there_be_j
  build_service_request_with_project

  describe "set visit page" do

    let!(:service_request)  { FactoryGirl.create_without_validation(:service_request) }
    let!(:arm)              { FactoryGirl.create(:arm, :visit_count => 10)}

    it "should return 1 if arm visit count <= 5" do
      arm.update_attributes(visit_count: 0)
      service_request.set_visit_page(1, arm).should eq(1)
      arm.update_attributes(visit_count: 5)
      service_request.set_visit_page(1, arm).should eq(1)
    end

    it "should return 1 if there is the pages passed are <= 0" do
      service_request.set_visit_page(0, arm).should eq(1)
    end

    it "should return 1 if the pages passed are greater than the visit count divided by 5" do
      service_request.set_visit_page(3, arm).should eq(1)
    end

    it "should return the pages passed if above conditions are not true" do
      service_request.set_visit_page(2, arm).should eq(2)
    end
  end

  describe "identities" do

    let!(:core)               { FactoryGirl.create(:core, parent_id: program.id, process_ssrs: false) }
    let!(:user)               { FactoryGirl.create(:identity) }
    let!(:service_provider2)  { FactoryGirl.create(:service_provider, identity_id: user.id, organization_id: core.id) }

    context "relevant_service_providers_and_super_users" do

      it "should return all service providers and super users for related sub service requests" do
        service_request.relevant_service_providers_and_super_users.should include(jug2, jpl6)
      end

      it "should not return any identities from child organizations if process ssrs is not set" do
        service_request.relevant_service_providers_and_super_users.should_not include(user)
      end
    end
  end

  context "methods" do

    before :each do
      add_visits
    end

    describe "one time fee line items" do
      it "should return one time fee line items" do
        service_request.one_time_fee_line_items[0].service.name.should eq("One Time Fee")
      end
    end
    describe "has one time fee services" do
      it "should return true" do
        service_request.has_one_time_fee_services?.should eq(true)
      end
    end
    describe "has per patient per visit services" do
      it "should return true" do
        service_request.has_per_patient_per_visit_services?.should eq(true)
      end
    end
    describe "service list" do
      context "no param" do
        it "should return all services" do
          id = Organization.find_by_name("Office of Biomedical Informatics").id
          service_request.service_list[id][:services].size.should eq(2)
          service_request.service_list[id][:services].first[:name].should eq("One Time Fee")
          service_request.service_list[id][:services].last[:name].should eq("Per Patient")
        end
      end
      context "true param" do
        it "should return one time fee services" do
          id = Organization.find_by_name("Office of Biomedical Informatics").id
          service_request.service_list(true)[id][:services].size.should eq(1)
          service_request.service_list(true)[id][:services].first[:name].should eq("One Time Fee")
        end
      end
      context "false param" do
        it "should return per patient services" do
          id = Organization.find_by_name("Office of Biomedical Informatics").id
          service_request.service_list(false)[id][:services].size.should eq(1)
          service_request.service_list(false)[id][:services].last[:name].should eq("Per Patient")
        end
      end
    end

    describe "create_line_items_for_service" do
      before :each do
        @new_service      = FactoryGirl.create(:service, organization_id: program.id, name: 'New One Time Fee')
        @optional_service = FactoryGirl.create(:service, organization_id: program.id, name: 'Optional One Time Fee')
        @required_service = FactoryGirl.create(:service, organization_id: program.id, name: 'Required One Time Fee')
        @disabled_program = FactoryGirl.create(:program, type: 'Program', parent_id: provider.id, name: 'Disabled', order: 1, abbreviation: 'Disabled Informatics', process_ssrs: 0, is_available: 0)
        @disabled_service = FactoryGirl.create(:service, organization_id: @disabled_program.id, name: 'Disabled Program Service')
        FactoryGirl.create(:service_relation, service_id: @new_service.id, related_service_id: @optional_service.id, optional: true)
        FactoryGirl.create(:service_relation, service_id: @new_service.id, related_service_id: @required_service.id, optional: false)
        FactoryGirl.create(:service_relation, service_id: @new_service.id, related_service_id: @disabled_service.id, optional: false)
        @line_items = service_request.create_line_items_for_service(service: @new_service, optional: true, existing_service_ids: [], allow_duplicates: true, recursive_call: false)
      end

      it 'should add optional services' do
        @line_items.map {|li| li.service.name}.include?(@optional_service.name).should eq(true)
      end

      it 'should add required services' do
        @line_items.map {|li| li.service.name}.include?(@required_service.name).should eq(true)
      end

      it 'should not add disabled services' do
        @line_items.map {|li| li.service.name}.include?(@disabled_service.name).should eq(false)
      end
    end
  end

  describe "cost calculations" do
    #USE_INDIRECT_COST = true  #For testing indirect cost

    before :each do
      add_visits
      @protocol = service_request.protocol
      @protocol.update_attributes(funding_status: "funded", funding_source: "federal", indirect_cost_rate: 200)
      @protocol.save :validate => false
      service_request.reload
    end

    context "total direct cost one time" do
      it "should return the sum of all line items one time fee direct cost" do
        service_request.total_direct_costs_one_time.should eq(5000)
      end
    end

    context "total indirect cost one time" do
      it "should return the sum of all line items one time fee indirect cost" do
        if USE_INDIRECT_COST
          service_request.total_indirect_costs_one_time.should eq(10000)
        else
          service_request.total_indirect_costs_one_time.should eq(0.0)
        end
      end
    end

    context "total cost one time" do
      it "should return the sum of all line items one time fee direct and indirect costs" do
        if USE_INDIRECT_COST
          service_request.total_costs_one_time.should eq(15000)
        else
          service_request.total_costs_one_time.should eq(5000)
        end
      end
    end

    context "total direct cost" do
      it "should return the sum of all line items direct cost" do
        service_request.direct_cost_total.should eq(605000)
      end
    end

    context "total indirect cost" do
      it "should return the sum of all line items indirect cost" do
        if USE_INDIRECT_COST
          service_request.indirect_cost_total.should eq(1210000)
        else
          service_request.indirect_cost_total.should eq(0.0)
        end
      end
    end

    context "grand total" do
      it "should return the grand total of all costs" do
        if USE_INDIRECT_COST
          service_request.grand_total.should eq(1815000)
        else
          service_request.grand_total.should eq(605000)
        end
      end
    end

    context "total direct cost per patient" do

      it "should return the sum of all line items visit-based direct cost" do
        service_request.total_direct_costs_per_patient.should eq(600000)
      end
    end

    context "total indirect cost per patient" do

      it "should return the sum of all line items visit-based indirect cost" do
        if USE_INDIRECT_COST
          service_request.total_indirect_costs_per_patient.should eq(1200000)
        else
          service_request.total_indirect_costs_per_patient.should eq(0.0)
        end
      end
    end

    context "total costs per patient" do

      it "should return the total of the direct and indirect costs" do
        if USE_INDIRECT_COST
          service_request.total_costs_per_patient.should eq(1800000)
        else
          service_request.total_costs_per_patient.should eq(600000.0)
        end
      end
    end
  end
end
