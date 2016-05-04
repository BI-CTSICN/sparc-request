require 'rails_helper'

RSpec.describe 'dashboard/notifications/_notifications', type: :view do
  include RSpecHtmlMatchers

  describe "recipient dropdown" do
    before(:each) do
      protocol = build_stubbed(:protocol)
      an_authorized_user = build_stubbed(:identity, first_name: "Jane", last_name: "Doe")
      allow(protocol).to receive(:project_roles).and_return([build_stubbed(:project_role, identity: an_authorized_user, protocol: protocol)])

      service_requester = build_stubbed(:identity, first_name: "John", last_name: "Doe")
      service_request = build_stubbed(:service_request, service_requester: service_requester, protocol: protocol)

      clinical_provider = build_stubbed(:identity, first_name: "Dr.", last_name: "Feelgood")
      organization = build_stubbed(:organization)
      allow(organization).to receive_message_chain(:service_providers, :includes).
        with(:identity).
        and_return([build_stubbed(:clinical_provider, identity: clinical_provider, organization: organization)])

      @sub_service_request = build_stubbed(:sub_service_request, service_request: service_request)
      allow(@sub_service_request).to receive(:organization).and_return(organization)

      @logged_in_user = build_stubbed(:identity)
    end

    context "user an admin" do
      it "should show authorized users, but not clinical providers or the service requester" do
        render "dashboard/notifications/notifications", sub_service_request: @sub_service_request, user: @logged_in_user, admin: true

        expect(response).to have_tag("select") do
          with_option(/Primary-pi: Jane Doe/)
          without_option(/John Doe/)
          without_option(/Dr\. Feelgood/)
        end
      end
    end

    context "user not an admin" do
      it "should show clinical providers and authorized users, but not the service requester" do
        render "dashboard/notifications/notifications", sub_service_request: @sub_service_request, user: @logged_in_user, admin: false

        expect(response).to have_tag("select") do
          with_option(/Primary-pi: Jane Doe/)
          with_option(/Dr\. Feelgood/)
          without_option(/John Doe/)
        end
      end
    end
  end
end
