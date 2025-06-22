# warn_indent: true
# frozen_string_literal: true

# Application Base
class ApplicationController < Sinatra::Base
  configure :production, :development do
    set :bind, '0.0.0.0'
    set :port, 3000

    enable :logging
  end

  helpers do
    def request_params
      body = JSON.parse(request.body.read)
      body.transform_keys!(&:to_sym)
    rescue JSON::ParserError
      render json: { data: nil, errors: 'Invalid JSON format' }.to_json, status: 400
    end

    def render(json:, status: 200)
      content_type :json
      halt status, json
    end
  end
end
