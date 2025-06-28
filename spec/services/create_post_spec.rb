# frozen_string_literal: true

require 'spec_helper'

RSpec.describe CreatePost, type: :service do
  subject(:service) { described_class }

  context 'with valid post' do
    let(:record) { create(:post) }
    let(:data) { { title: 'Sample Post', content: 'Sample post content.', user_id: 42 } }

    it 'returns a success' do
      expect(service.call(data)).to be_success
    end
  end

  context 'with invalid post' do
    let(:data) { { title: 'Sample Post', content: '', user_id: 42 } }

    it 'returns a failure' do
      expect(service.call(data)).not_to be_success
      expect(service.call(data).error).to eq(content: ['is not present'])
    end
  end
end
