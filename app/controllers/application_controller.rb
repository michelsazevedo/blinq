# frozen_string_literal: true

# Application Base
class ApplicationController < Sinatra::Base
  use LogzMiddleware

  configure :production, :development do
    set :bind, '0.0.0.0'
    set :port, 3000
    set :logger, Sinatra.logger
  end

  helpers do
    def request_params
      body = Oj.load(request.body.read)
      body.transform_keys!(&:to_sym)
    rescue Oj::ParseError
      render json: Oj.dump({ data: nil, errors: 'Invalid JSON format' }), status: 400
    end

    def render(json:, status: 200)
      content_type :json
      halt status, json
    end
  end
end
