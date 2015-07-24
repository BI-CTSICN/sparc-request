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
include CapybaraCatalogManager
include CapybaraProper


RSpec.describe 'Catalog Manager', :happy_test do
  let_there_be_lane
  fake_login_for_each_test

  it 'Should create a functional catalog', js: true do
    createTags
    visit catalog_manager_root_path

    create_new_institution 'someInst'
    create_new_provider 'someProv', 'someInst'
    create_new_program 'someProg', 'someProv'
    create_new_core 'someCore', 'someProg'
    create_new_service 'someService', 'someCore', otf: false
    create_new_service 'someService2', 'someCore', otf: true

    create_new_institution 'Medical University of South Carolina', {abbreviation: 'MUSC', tags: ['Clinical work fulfillment']}
    create_new_provider 'South Carolina Clinical and Translational Institute (SCTR)', 'Medical University of South Carolina', {abbreviation: 'SCTR1', tags: ['Clinical work fulfillment']}
    create_new_program 'Office of Biomedical Informatics', 'South Carolina Clinical and Translational Institute (SCTR)', {abbreviation: 'Informatics', tags: ['Clinical work fulfillment']}
    create_new_program 'Clinical and Translational Research Center (CTRC)', 'South Carolina Clinical and Translational Institute (SCTR)', {abbreviation: 'Informatics', process_ssrs: true, tags: ['Clinical work fulfillment','Nexus']}
    create_new_core 'Clinical Data Warehouse', 'Office of Biomedical Informatics', {tags: ['Clinical work fulfillment']}
    create_new_core 'Nursing Services', 'Clinical and Translational Research Center (CTRC)', {tags: ['Clinical work fulfillment']}
    create_new_service 'MUSC Research Data Request (CDW)', 'Clinical Data Warehouse', {otf: true, unit_type: 'Per Query', unit_factor: 1, rate: '2.00', unit_minimum: 1, tags: ['Clinical work fulfillment']}
    create_new_service 'Breast Milk Collection', 'Nursing Services', {otf: false, unit_type: 'Per patient/visit', unit_factor: 1, rate: '6.36', unit_minimum: 1, tags: ['Clinical work fulfillment']}

    create_new_service 'SuperService 1', 'Office of Biomedical Informatics',{otf: false, rate: '500000.00', unit_minimum: 5}
    create_new_service 'SuperService 2', 'Clinical and Translational Research Center (CTRC)',{otf: true, rate: '500000.00', unit_minimum: 5}

    create_new_institution 'invisibleInstitution', is_available: false
    create_new_institution 'Institute of Invisibility'
    create_new_provider 'invisibleProv', 'Institute of Invisibility', is_available: false
    create_new_provider 'Provider of Invisibility', 'Institute of Invisibility'
    create_new_program 'invisibleProg', 'Provider of Invisibility', is_available: false
    create_new_program 'Program of Invisibility','Provider of Invisibility'
    create_new_core 'invisibleCore','Program of Invisibility', is_available: false
    create_new_core 'Core of Invisibility','Program of Invisibility'
    create_new_service 'invisibleService', 'Core of Invisibility', is_available: false
    create_new_service 'Service of Visibility','Core of Invisibility'
    create_new_service 'Linked Service of Visibility','Core of Invisibility',linked: {:on? => true, service: 'Service of Visibility', :required? => true, :quantity? => true, quantityNum: 5}



    visit root_path

    navigateCatalog "Medical University of South Carolina", "South Carolina Clinical and Translational Institute (SCTR)", "Office of Biomedical Informatics"
    expect(page).to have_xpath("//a[text()='MUSC Research Data Request (CDW)']")
    expect(page).to have_xpath("//a[text()='SuperService 1']")

    navigateCatalog "Medical University of South Carolina", "South Carolina Clinical and Translational Institute (SCTR)", "Clinical and Translational Research Center (CTRC)"
    expect(page).to have_xpath("//a[text()='SuperService 2']")
    expect(page).to have_xpath("//a[text()='Breast Milk Collection']")
    click_link("Medical University of South Carolina")

    #**Check visibility conditions**#
    click_link('Institute of Invisibility')
    wait_for_javascript_to_finish
    expect(page).not_to have_xpath("//a[text()='invisibleInstitution']")
    expect(page).not_to have_xpath("//a[text()='invisibleProv']")
    click_link('Provider of Invisibility')
    wait_for_javascript_to_finish
    click_link('Program of Invisibility')#For some reason, this doesn't work
    wait_for_javascript_to_finish
    click_link('Program of Invisibility')#If you only click it one time.
    wait_for_javascript_to_finish
    click_link('Program of Invisibility')#Selenium issue-not sparc I believe.
    wait_for_javascript_to_finish
    expect(page).not_to have_xpath("//a[text()='invisibleProg']")
    expect(page).not_to have_xpath("//a[text()='invisibleCore']")
    expect(page).not_to have_xpath("//a[text()='invisibleService']")
    expect(page).to have_xpath("//a[text()='Service of Visibility']")
    clickOffAndWait
    expect(page).to have_xpath("//a[text()='Linked Service of Visibility']")
    #**END Check visibility conditions END**#

    #**Check linked service adding**#
    addService "Linked Service of Visibility"
    checkLineItemsNumber("2")
    removeService "Linked Service of Visibility"
    checkLineItemsNumber("1")
    removeService "Service of Visibility"
    checkLineItemsNumber("0")
    addService "Service of Visibility"
    checkLineItemsNumber("1")
    removeService "Service of Visibility"
    #**END Check linked service adding END**#
  end
end
