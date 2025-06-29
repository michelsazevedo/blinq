# frozen_string_literal: true

require 'spec_helper'

RSpec.describe PostsController, type: :controller do
  describe 'GET /' do
    let(:posts) do
      [ { id: 1, title: 'Sample Post', content: 'Some content', user_id: 42 } ]
    end

    before do
      allow(GetPosts).to receive(:call).and_return(posts)
      get '/'
    end

    it 'returns 200 OK' do
      expect(last_response.status).to eq(200)
    end

    it 'returns a list of posts in JSON format' do
      response_body = Oj.load(last_response.body, symbol_keys: true)

      expect(response_body[:data]).to eq(posts)
      expect(response_body[:error]).to be_nil
    end
  end

  describe 'POST /' do
    context 'with valid post' do
      let(:record) { create(:post) }
      let(:data) { { title: 'Sample Post', content: 'Sample post content.', user_id: 42 }.to_json }
      let(:service) { double('CreatePost') }

      before do
        allow(service).to receive(:success).and_yield(record)
        allow(service).to receive(:failure)

        allow(CreatePost).to receive(:call).and_yield(service)
        post '/', data, { 'CONTENT_TYPE' => 'application/json' }
      end

      it 'returns a 200 status code' do
        expect(last_response.status).to eq(200)
      end

      it 'returns the post data in JSON' do
        response_body = Oj.load(last_response.body)

        expect(response_body['data']).to eq(Oj.load(record.to_json))
        expect(response_body['errors']).to be_nil
      end
    end

    context 'with invalid post' do
      let(:data) { { title: 'Sample Post', content: '', user_id: 42 }.to_json }
      let(:service) { double('CreatePost') }
      let(:errors) { { content: ['is not present'] } }

      before do
        allow(service).to receive(:success)
        allow(service).to receive(:failure).and_yield(errors)

        allow(CreatePost).to receive(:call).and_yield(service)
        post '/', data, { 'CONTENT_TYPE' => 'application/json' }
      end

      it 'returns a 422 status code' do
        expect(last_response.status).to eq(422)
      end

      it 'returns the error message in JSON' do
        response_body = Oj.load(last_response.body, symbolize_names: true)

        expect(response_body).to eq(data: nil, errors: errors)
      end
    end
  end
end
