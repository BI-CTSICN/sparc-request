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

RSpec.describe "study schedule", js: true do
  let_there_be_lane
  let_there_be_j
  fake_login_for_each_test
  build_service_request_with_project()

  context "using the calendar" do

    before :each do
      create_visits
      sub_service_request.update_attributes(in_work_fulfillment: true)
      visit study_tracker_sub_service_request_path sub_service_request.id
      arm1.reload
      arm2.reload
    end

    after :each do
      wait_for_javascript_to_finish
    end

    describe "back link" do
      it "should take you back to study tracker landing page" do
        click_link "Back to Clinical Work Fulfillment"
        wait_for_javascript_to_finish
        expect(current_path).to eq("/clinical_work_fulfillment")
      end
    end
    describe "per patient per visit" do

      describe "template tab" do
        describe "changing a visit day" do
          it "should not allow invalid days to be entered" do
            wait_for_javascript_to_finish
            elements = all("#day.visit_day")
            #set visit days on either side
            elements[0].set(1)
            page.execute_script("$('#day.position_1:first').change()")
            sleep 1

            elements[2].set(5)
            page.execute_script("$('#day.position_3:first').change()")
            sleep 1

            elements[1].set(1000)
            accept_alert("The days are out of order. This day appears to go after the next day.\n") do
              page.execute_script("$('#day.position_2:first').change()")
              sleep 1
            end
            wait_for_javascript_to_finish

            elements[1].set(0)
            accept_alert("The days are out of order. This day appears to go before the previous day.\n") do
              find(".user-information-body").click #This is a different method of triggering the outfocus. For some reason, selenium goes bonkers after the first alert box.
              sleep 1
            end
          end
          it "should not allow invalid day ranges to be entered" do
            wait_for_javascript_to_finish
            sleep 2
            first("#window_before.visit_window_before").set '-1'
            accept_alert("You've entered an invalid number for the before window. Please enter a positive valid number\n") do
              find(".user-information-body").click
              sleep 1
            end
          end
        end
        describe "adding a new visit" do
          it "should render a pop up in which you can change the visit successfully with valid input" do
            wait_for_javascript_to_finish
            select "Insert before 3 - Visit 3", from: "visit_position"
            find(:xpath,"//a[@class='add_visit_link']").click
            expect(page).to have_content ("Add a new visit")#checks that pop up is rendered
            fill_in 'visit_name', with: 'test visit name' #checks that name is changed
            fill_in 'visit_day', with: 2 #must set a value for visit 1 and visit 2 in order to test it
            click_button 'submit_visit'
            expect(page).to have_content 'Service request has been saved'
            wait_for_javascript_to_finish

            select "Insert before 2 - Visit 2", from: "visit_position"
            find(:xpath,"//a[@class='add_visit_link']").click
            fill_in "visit_day", with: 1
            click_button "submit_visit"
            expect(page).to have_content 'Service request has been saved'
            wait_for_javascript_to_finish

            select "Insert before 3 - Visit 2", from: "visit_position"
            find(:xpath,"//a[@class='add_visit_link']").click
            fill_in "visit_day", with: -30
            click_button "submit_visit"
            expect(page).to have_content "Out of order the days are out of order. this day appears to go before the previous day..."
            fill_in "visit_day", with: 2
            fill_in "visit_window_before", with: -20
            click_button "submit_visit"
            expect(page).to have_content "Invalid window before you've entered an invalid number for the before window. please enter a positive valid number.."
            fill_in "visit_window_before", with:1
            click_button "submit_visit"
            wait_for_javascript_to_finish

            select "Insert before 2 - Visit Name", from: "visit_position"
            find(:xpath,"//a[@class='add_visit_link']").click
            fill_in "visit_day", with: -20
            click_button "submit_visit"
            expect(page).to have_content "Out of order the days are out of order. this day appears to go before the previous day..."
            fill_in "visit_day", with: 30002
            click_button "submit_visit"
            expect(page).to have_content "Out of order the days are out of order. this day appears to go after the next day.\n"
          end
        end


        describe "selecting check row button" do

          it "should check all visits" do
            click_link "check_row_#{arm1.line_items_visits.first.id}_template"
            wait_for_javascript_to_finish
            arm1.line_items_visits.first.visits.each do |visit|
              expect(visit.research_billing_qty).to eq(1)
            end
          end

          it "should uncheck all visits" do
            click_link "check_row_#{arm1.line_items_visits.first.id}_template"
            wait_for_javascript_to_finish

            click_link "check_row_#{arm1.line_items_visits.first.id}_template"
            wait_for_javascript_to_finish
            arm1.line_items_visits.first.visits.each do |visit|
              expect(visit.research_billing_qty).to eq(0)
            end
          end
        end

        describe "selecting check column button" do

          it "should check all visits in the given column" do
            wait_for_javascript_to_finish
            first("#check_all_column_3").click
            wait_for_javascript_to_finish

            expect(find("#visits_#{arm1.line_items_visits.first.visits[2].id}").checked?).to eq(true)
          end

          it "should uncheck all visits in the given column" do
            wait_for_javascript_to_finish
            first("#check_all_column_3").click
            wait_for_javascript_to_finish


            expect(find("#visits_#{arm1.line_items_visits.first.visits[2].id}").checked?).to eq(true)
            wait_for_javascript_to_finish
            first("#check_all_column_3").click
            wait_for_javascript_to_finish

            expect(find("#visits_#{arm1.line_items_visits.first.visits[2].id}").checked?).to eq(false)
          end
        end
      end

      describe "billing strategy tab" do
        before :each do
          click_link "billing_strategy_tab"
          @visit_id = arm1.line_items_visits.first.visits[1].id
        end

        describe "selecting check all row button" do

          it "should overwrite the quantity in research billing box" do
            fill_in "visits_#{@visit_id}_research_billing_qty", with: 10
            wait_for_javascript_to_finish
            click_link "check_row_#{arm1.line_items_visits.first.id}_billing_strategy"
            wait_for_javascript_to_finish
            expect(find("#visits_#{@visit_id}_research_billing_qty")).to have_value("1")
          end
        end

        describe "increasing the 'R' billing quantity" do
          it "should increase the total cost" do

            find("#visits_#{@visit_id}_research_billing_qty").set("")
            find("#visits_#{@visit_id}_research_billing_qty").click()
            fill_in( "visits_#{@visit_id}_research_billing_qty", with: 10)
            find("#visits_#{@visit_id}_insurance_billing_qty").click()
            wait_for_javascript_to_finish

            all(".pp_max_total_direct_cost.arm_#{arm1.id}").each do |x|
              if x.visible?
                expect(x).to have_exact_text("$300.00")
              end
            end
          end

          it "should update each visits maximum costs" do

            find("#visits_#{@visit_id}_research_billing_qty").set("")
            find("#visits_#{@visit_id}_research_billing_qty").click()
            fill_in "visits_#{@visit_id}_research_billing_qty", with: 10
            find("#visits_#{@visit_id}_insurance_billing_qty").click()

            wait_for_javascript_to_finish

            sleep 3 # TODO: ugh: I got rid of all the sleeps, but I can't get rid of this one

            all(".visit_column_2.max_direct_per_patient.arm_#{arm1.id}").each do |x|
              if x.visible?
                expect(x).to have_exact_text("$300.00")
              end
            end

            if USE_INDIRECT_COST
              all(".visit_column_2.max_indirect_per_patient.arm_#{arm1.id}").each do |x|
                if x.visible?
                  expect(x).to have_exact_text "$150.00"
                end
              end
            end
          end
        end

        describe "increasing the '%' or 'T' billing quantity" do

          before :each do
            @visit_id = arm1.line_items_visits.first.visits[1].id
          end

          it "should not increase the total cost" do

            remove_from_dom('.pp_max_total_direct_cost')

            # Putting values in these fields should not increase the total
            # cost
            fill_in "visits_#{@visit_id}_insurance_billing_qty", with: 10
            find("#visits_#{@visit_id}_effort_billing_qty").click()

            fill_in "visits_#{@visit_id}_effort_billing_qty", with: 10
            find("#visits_#{@visit_id}_research_billing_qty").click()

            fill_in "visits_#{@visit_id}_research_billing_qty", with: 1
            find("#visits_#{@visit_id}_insurance_billing_qty").click()

            all(".pp_max_total_direct_cost.arm_#{arm1.id}").each do |x|
              if x.visible?
                expect(x).to have_exact_text "$30.00"
              end
            end
          end
        end
      end

      describe "hovering over visit name text box" do

        it "should open up a qtip message" do
          wait_for_javascript_to_finish
          first('.visit_name').click
          wait_for_javascript_to_finish
          expect(page).to have_content("Click to rename your visits.")
        end
      end
    end

    describe "one time fees" do

      #TODO: These two are randomly failing due to something with capybara.  Both
      # have been thoroughly manualy tested.
       describe "changing the number of units" do

        it "should save the new number of units" do
          find("#quantity.line_item_quantity").click
          find("#quantity.line_item_quantity").set("6")
          sleep 1
          page.execute_script("$('#quantity.line_item_quantity').change()")
          wait_for_javascript_to_finish
          sleep 2
          expect(find(".line_item_quantity")).to have_value("6")
        end
      end

      describe "changing the units per quantity" do

        it "should save the new units per quantity" do
          find(".units_per_quantity").click
          find(".units_per_quantity").set("5")
          sleep 1
          page.execute_script("$('.units_per_quantity').change()")
          wait_for_javascript_to_finish
          sleep 2
          expect(find(".units_per_quantity")).to have_value("5")
        end
      end

      describe "adding a service" do

        it "should successfully add and save a new service" do
          click_on "Add One-Time Fee Service"
          sleep 1
          expect(service.line_items.count).to eq(2)
        end
      end

      describe "deleting a service" do

        it "should successfully delete a service" do
          within "#one_time_fees" do
            accept_confirm("Are you sure you want to remove this service?") do
              click_on "Cancel"
            end
            sleep 1
            expect(service.line_items.size).to eq(0)
          end
        end
      end
    end
  end

  context "adding and deleting" do

    before :each do
      sub_service_request.update_attributes(in_work_fulfillment: true)
      line_item3 = create(:line_item, service_request_id: service_request.id, service_id: service2.id, sub_service_request_id: sub_service_request.id, quantity: 0)
      create_visits
      visit study_tracker_sub_service_request_path sub_service_request.id
    end

    describe "deleting" do

      context "a line_item_visit" do

        it "should delete the line_items_visit" do
          expect(arm1.line_items_visits.size).to eq(2)

          #Delete the new line_item_visit
          within("table.arm_id_#{arm1.id} tr.line_item.odd") do
            click_on "Cancel"
          end

          wait_for_javascript_to_finish
          expect(arm1.line_items_visits.size).to eq(1)
        end

        it "should warn user about deleting procedures" do
          accept_confirm("Are you sure that you want to remove this service from all subjects' visit calendars in this arm?") do
            within("table.arm_id_#{arm1.id} tr.line_item.odd") do
              click_on "Cancel"
            end
            wait_for_javascript_to_finish
          end
        end
      end

      context "a line_item" do

        it "should delete the line_item" do
          expect(arm1.line_items.size).to eq(2)
          accept_confirm("Are you sure that you want to remove this service from all subjects' visit calendars?") do
            click_button('Remove Service from all patients')
          end

          wait_for_javascript_to_finish
          expect(arm1.line_items.size).to eq(1)
        end
      end
    end

    describe "adding a service to all patients" do

      it "should add the service to the calendar" do
        click_on "Add Service to all patients"
        wait_for_javascript_to_finish
        expect(arm1.line_items_visits.size).to eq(3)
        expect(arm2.line_items_visits.size).to eq(3)
      end
    end
  end
end
