# frozen_string_literal: true

require 'uri'
require 'securerandom'

# Logz middleware
class LogzMiddleware
  def initialize(app)
    @app = app
  end

  def call(env)
    request = Rack::Request.new(env)
    start_time = Time.now

    Sinatra.logger.context(
      {
        path: URI(request.url).path,
        ip: request.ip,
        user_agent: request.user_agent,
        method: request.request_method,
        host: request.host
      }
    )

    status, headers, response = @app.call(env)
    latency = ((Time.now - start_time) * 1000).round(2)
    Sinatra.logger.info(nil, status: status, latency: latency)

    [status, headers, response]
  end
end
