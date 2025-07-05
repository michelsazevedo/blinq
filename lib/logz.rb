# frozen_string_literal: true

require 'logger'
require 'oj'

# Structured logging
class Logz
  def initialize(app_name, log_level = :info, output = $stdout)
    @app_name = app_name
    @log_level = log_level

    @logger = Logger.new(output)
    @logger.level = Logger.const_get(log_level.to_s.upcase)

    @logger.formatter = proc do |severity, datetime, _, msg|
      format_log(severity, datetime, msg)
    end

    @context = {}
  end

  %i[debug info warn error fatal].each do |severity|
    define_method(severity) do |message, opts = {}|
      log(severity, message, opts)
    end
  end

  def context(opts)
    Thread.current[@app_name] ||= {}
    Thread.current[@app_name].merge!(opts)
  end

  private

  def log(level, message, opts = {})
    @logger.send(level, { message: message }.merge(opts))
  end

  def format_log(level, datetime, message)
    log_entry = { time: datetime.to_i, level: level, app: @app_name, **message.compact }
    log_entry.merge!(Thread.current[@app_name] || {})

    "#{Oj.dump(log_entry)} \n"
  end
end
