# warn_indent: true
# frozen_string_literal: true

# Health Check
class HealthzController < ApplicationController
  get '/' do
    render json: { status: 'Ok!' }.to_json
  end
end
