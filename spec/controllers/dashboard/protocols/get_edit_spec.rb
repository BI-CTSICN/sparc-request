require 'rails_helper'

RSpec.describe Dashboard::ProtocolsController do
  describe 'GET #edit' do
    context 'user is an Authorized User' do
      context 'user not authorized to edit Protocol' do
        before(:each) do
          @logged_in_user = build_stubbed(:identity)

          @protocol = findable_stub(Protocol) do
            build_stubbed(:protocol, type: "Project")
          end
          authorize(@logged_in_user, @protocol, can_edit: false)

          log_in_dashboard_identity(obj: @logged_in_user)
          get :edit, id: @protocol.id
        end

        it "should use ProtocolAuthorizer to authorize user" do
          expect(ProtocolAuthorizer).to have_received(:new).
            with(@protocol, @logged_in_user)
        end

        it { is_expected.to respond_with :ok }
        it { is_expected.to render_template "service_requests/_authorization_error" }
      end

      context "user authorized to edit Protocol" do
        before(:each) do
          @logged_in_user = build_stubbed(:identity)

          @protocol = findable_stub(Protocol) do
            build_stubbed(:protocol, type: "Project")
          end
          allow(@protocol).to receive(:valid?).and_return(true)
          allow(@protocol).to receive(:populate_for_edit)

          authorize(@logged_in_user, @protocol, can_edit: true)

          log_in_dashboard_identity(obj: @logged_in_user)
          get :edit, id: @protocol.id
        end

        it "should assign @protocol_type to type of Protocol" do
          expect(assigns(:protocol_type)).to eq("Project")
        end

        it "should populate Protocol for edit" do
          expect(@protocol).to have_received(:populate_for_edit)
        end

        it { is_expected.to respond_with :ok }
        it { is_expected.to render_template "dashboard/protocols/edit" }
      end
    end

    context 'user has Admin access' do
      context 'user not authorized to view Protocol' do
        before :each do
          @logged_in_user = create(:identity)
          @protocol       = create(:protocol_without_validations, type: 'Project')

          log_in_dashboard_identity(obj: @logged_in_user)

          get :edit, id: @protocol.id
        end

        it 'should set @admin to false' do
          expect(assigns(:admin)).to eq(false)
        end

        it { is_expected.to respond_with :ok }
        it { is_expected.to render_template "service_requests/_authorization_error" }
      end

      context 'user authorized to view Protocol as Super User' do
        before :each do
          @logged_in_user = create(:identity)
          @protocol       = create(:protocol_without_validations, type: 'Project')
          organization    = create(:organization)
          service_request = create(:service_request_without_validations, protocol: @protocol)
                            create(:sub_service_request_without_validations, organization: organization, service_request: service_request)
                            create(:super_user, identity: @logged_in_user, organization: organization)

          log_in_dashboard_identity(obj: @logged_in_user)

          get :edit, id: @protocol.id
        end

        it 'should set @admin to true' do
          expect(assigns(:admin)).to eq(true)
        end

        it { is_expected.to respond_with :ok }
      end

      context 'user authorized to view Protocol as Service Provider' do
        before :each do
          @logged_in_user = create(:identity)
          @protocol       = create(:protocol_without_validations, type: 'Project')
          organization    = create(:organization)
          service_request = create(:service_request_without_validations, protocol: @protocol)
                            create(:sub_service_request_without_validations, organization: organization, service_request: service_request)
                            create(:service_provider, identity: @logged_in_user, organization: organization)

          log_in_dashboard_identity(obj: @logged_in_user)

          get :edit, id: @protocol.id
        end

        it 'should set @admin to true' do
          expect(assigns(:admin)).to eq(true)
        end

        it { is_expected.to respond_with :ok }
      end
    end
  end
end
