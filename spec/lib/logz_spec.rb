# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Logz do
  subject(:logger) { described_class.new(app_name, :info, output) }

  let(:app_name) { 'blinq' }
  let(:output) { StringIO.new }

  before { Thread.current[app_name] = nil }
  after  { Thread.current[app_name] = nil }

  describe 'logging methods' do
    before { logger.instance_variable_get(:@logger).level = Logger::DEBUG }

    %i[debug info warn error fatal].each do |level|
      context ".#{level}" do
        it "logs a #{level} message with correct format" do
          logger.send(level, 'Test message')
          log_line = Oj.load(output.string)

          expect(log_line)
            .to include(
              'app' => app_name,
              'level' => level.to_s.upcase,
              'message' => 'Test message',
              'time' => be_a(Integer)
            )
        end
      end
    end
  end
end
