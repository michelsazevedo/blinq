# frozen_string_literal: true

workers ENV.fetch("WEB_CONCURRENCY", 4)
threads_count = ENV.fetch("RACK_MAX_THREADS", 8)
threads threads_count, threads_count

port        ENV['PORT'] || 3000
environment ENV['RACK_ENV'] || 'development'

plugin :tmp_restart
