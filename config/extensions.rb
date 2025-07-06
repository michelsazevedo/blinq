# frozen_string_literal: true

require_relative '../lib/logz'
require_relative '../lib/cache'
require_relative '../lib/message_queue'

# Sinatra logging
module Sinatra
  class << self
    attr_accessor :logger, :cache, :queue
  end
end

Sinatra.logger = Logz.new(ENV.fetch('APP_NAME', 'blinq'), ENV.fetch('LOG_LEVEL', :info))
Sinatra.cache = Cache.configure(logger: Sinatra.logger)
Sinatra.queue = MessageQueue.new(logger: Sinatra.logger, heartbeat: 10)
