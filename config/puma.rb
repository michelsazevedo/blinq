# warn_indent: true
# frozen_string_literal: true

threads_count = ENV['RACK_MAX_THREADS'] || 5
threads threads_count, threads_count

port        ENV['PORT'] || 3000
environment ENV['RACK_ENV'] || 'development'

plugin :tmp_restart
