# warn_indent: true
# frozen_string_literal: true

# Health Check
class HealthzController < ApplicationController
  get '/' do
    content_type :json

    status 200
    body({ message: 'Everything is Ok ;-)' }.to_json)
  end
end
