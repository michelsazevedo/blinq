# frozen_string_literal: true

require 'bundler/setup'
require 'sinatra/base'
require 'zeitwerk'

require_relative 'sequeldb'
require_relative 'rabbitmq'

# Establish connection
SequelDb.establish_connection!

# Load dependencies
Bundler.setup :default, Sinatra::Application.environment
Bundler.require

Sinatra::Base.settings.root = File.join(File.dirname(__FILE__), '..', 'app')

# Set autoloading directories
loader = Zeitwerk::Loader.new
Dir.glob(File.join(Sinatra::Base.settings.root, "**", "*")).each do |path|
  loader.push_dir path if File.directory?(path)
end

# Add the lib directory
loader.push_dir File.join(File.dirname(__FILE__), '..', 'lib')
loader.setup
