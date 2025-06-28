# frozen_string_literal: true

require 'spec_helper'

RSpec.describe HealthzController, type: :controller do
  describe 'GET #index' do
    it 'returns http success' do
      get '/'
      expect(last_response.status).to be_eql(200)
    end
  end
end
