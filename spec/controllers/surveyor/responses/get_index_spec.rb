# Copyright © 2011-2018 MUSC Foundation for Research Development
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

RSpec.describe Surveyor::ResponsesController, type: :controller do
  stub_controller
  let!(:before_filters) { find_before_filters }
  let!(:logged_in_user) { create(:identity) }

  describe '#index' do
    it 'should call before_filter #authenticate_identity!' do
      expect(before_filters.include?(:authenticate_identity!)).to eq(true)
    end

    context 'format.html' do
      it 'should assign @filterrific' do
        get :index, params: {}, format: :html

        expect(assigns(:filterrific)).to be_a(Filterrific::ParamSet)
        expect(assigns(:filterrific).model_class).to eq(Response)
      end

      it 'should assign @type' do
        get :index, params: {
          filterrific: {
            with_type: 'SystemSurvey'
          }
        }, format: :html

        expect(assigns(:type)).to eq('Survey')
      end

      it 'should assign @responses' do
        @resp = create(:response, survey: create(:form))

        get :index, params: {}, format: :html

        expect(assigns(:responses)).to be_a(ActiveRecord::Relation)
        expect(assigns(:responses).first).to eq(@resp)
      end

      it 'should respond ok' do
        get :index, params: {}, format: :html

        expect(controller).to respond_with(:ok)
      end

      it 'should render template' do
        get :index, params: {}, format: :html

        expect(response).to render_template(:index)
      end
    end

    context 'format.js' do
      it 'should assign @filterrific' do
        get :index, params: {}, format: :js, xhr: true

        expect(assigns(:filterrific)).to be_a(Filterrific::ParamSet)
        expect(assigns(:filterrific).model_class).to eq(Response)
      end

      it 'should assign @type' do
        get :index, params: {
          filterrific: {
            with_type: 'SystemSurvey'
          }
        }, format: :js, xhr: true

        expect(assigns(:type)).to eq('Survey')
      end

      it 'should assign @responses' do
        @resp = create(:response, survey: create(:form))

        get :index, params: {}, format: :js, xhr: true

        expect(assigns(:responses)).to be_a(ActiveRecord::Relation)
        expect(assigns(:responses).first).to eq(@resp)
      end

      it 'should respond ok' do
        get :index, params: {}, format: :js, xhr: true

        expect(controller).to respond_with(:ok)
      end

      it 'should render template' do
        get :index, params: {}, format: :js, xhr: true

        expect(response).to render_template(:index)
      end
    end

    context 'format.json' do
      it 'should assign @filterrific' do
        get :index, params: {}, format: :json

        expect(assigns(:filterrific)).to be_a(Filterrific::ParamSet)
        expect(assigns(:filterrific).model_class).to eq(Response)
      end

      it 'should assign @type' do
        get :index, params: {
          filterrific: {
            with_type: 'SystemSurvey'
          }
        }, format: :json

        expect(assigns(:type)).to eq('Survey')
      end

      it 'should assign @responses' do
        @resp = create(:response, survey: create(:form))

        get :index, params: {}, format: :json

        expect(assigns(:responses)).to be_a(ActiveRecord::Relation)
        expect(assigns(:responses).first).to eq(@resp)
      end

      it 'should respond ok' do
        get :index, params: {}, format: :json

        expect(controller).to respond_with(:ok)
      end

      it 'should render template' do
        get :index, params: {}, format: :json

        expect(response).to render_template(:index)
      end
    end
  end
end
