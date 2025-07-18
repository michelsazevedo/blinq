# frozen_string_literal: true

require_relative './config/boot'

run Rack::URLMap.new(
  '/healthz' => HealthzController,
  '/posts'   => PostsController
)
