# frozen_string_literal: true

require 'logger'
require 'oj'

## Structured logger with per-thread context support and JSON-formatted output
#
# `Logz` wraps Ruby's standard Logger and formats logs as structured JSON
# It supports adding per-thread context and logging with custom fields
class Logz
  ## Initializes the structured logger
  #
  # @param app_name [String] Name of the application (used for context key and output)
  # @param log_level [Symbol] Log level (e.g., :info, :debug)
  # @param output [IO] Output stream (default: $stdout)
  def initialize(app_name, log_level = :info, output = $stdout)
    @app_name = app_name
    @log_level = log_level

    @logger = Logger.new(output)
    @logger.level = Logger.const_get(log_level.to_s.upcase)

    @logger.formatter = proc do |severity, datetime, _, message|
      format_log(severity, datetime, message)
    end

    @context = {}
  end

  ## Dynamically defines the following methods:
  #   - debug(message, opts = {})
  #   - info(message, opts = {})
  #   - warn(message, opts = {})
  #   - error(message, opts = {})
  #   - fatal(message, opts = {})
  #
  # Each logs a structured JSON entry at the appropriate level
  #
  # @param message [String] Main log message
  # @param opts [Hash] Additional key-value data to include
  # @return [void]
  %i[debug info warn error fatal].each do |severity|
    define_method(severity) do |message, opts = {}|
      log(severity, message, opts)
    end
  end

  ## Adds context for current thread (merged into all logs from this thread)
  #
  # @param opts [Hash] Key-value pairs to include in log entries
  # @return [void]
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
