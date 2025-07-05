# frozen_string_literal: true

require 'bundler/setup'
require 'sinatra/base'
require 'zeitwerk'
require 'oj'

require_relative 'sequeldb'
require_relative 'logging'

# Establish connection
SequelDb.establish_connection!

# Configure Oj
Oj.default_options = { mode: :compat }

# Load dependencies
Bundler.setup :default, Sinatra::Application.environment
Bundler.require

Sinatra::Base.settings.root = File.join(File.dirname(__FILE__), '..', 'app')

# Set autoloading directories
loader = Zeitwerk::Loader.new

Dir.glob(File.join(Sinatra::Base.settings.root, '**', '*')).each do |path|
  loader.push_dir path if File.directory?(path)
end

# Add the middleware directory
loader.push_dir File.join(File.dirname(__FILE__), 'middlewares')

# Add the lib directory
loader.push_dir File.join(File.dirname(__FILE__), '..', 'lib')

loader.setup
