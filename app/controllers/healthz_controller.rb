# frozen_string_literal: true

# Health Check
class HealthzController < ApplicationController
  get '/' do
    render json: { status: 'Ok!' }
  end
end
