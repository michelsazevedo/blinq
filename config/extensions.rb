# frozen_string_literal: true

require_relative '../lib/logz'
require_relative '../lib/cache'
require_relative '../lib/message_queue'

# Sinatra logging
module Sinatra
  class << self
    attr_accessor :logger, :cache, :queue

    def prod_env?
      ENV['RACK_ENV'] == 'production'
    end

    def test_env?
      ENV['RACK_ENV'] == 'test'
    end
  end
end

Sinatra.logger = Logz.new(ENV.fetch('APP_NAME', 'blinq'), ENV.fetch('LOG_LEVEL', :info))

unless Sinatra.test_env?
  Sinatra.cache = Cache.configure(logger: Sinatra.logger)
  Sinatra.queue = MessageQueue.new(logger: Sinatra.logger, heartbeat: 10)
end
