# warn_indent: true
# frozen_string_literal: true

ENV['RACK_ENV'] = 'test'

require 'simplecov'
SimpleCov.start

SimpleCov.minimum_coverage 94
SimpleCov.refuse_coverage_drop

require 'factory_bot'
require 'ffaker'
require 'rack/test'
require './config/boot'

Dir.glob(
  ['./spec/support/**/*.rb', './spec/factories/*.rb']
).each { |file| require file }

RSpec.configure do |config|
  config.include Rack::Test::Methods
  config.include FactoryBot::Syntax::Methods

  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.shared_context_metadata_behavior = :apply_to_host_groups

  config.after(:each) do
    SequelDb.sequel_instance_exec do |db|
      db[:posts].truncate
    end
  end
end
