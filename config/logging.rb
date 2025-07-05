# frozen_string_literal: true

require_relative '../lib/logz'

# Sinatra logging
module Sinatra
  class << self
    attr_accessor :logger
  end
end

Sinatra.logger = Logz.new(ENV.fetch('APP_NAME', 'blinq'), ENV.fetch('LOG_LEVEL', :info))
