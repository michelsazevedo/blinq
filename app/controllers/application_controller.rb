# warn_indent: true
# frozen_string_literal: true

# Application Base
class ApplicationController < Sinatra::Base
  configure :production, :development do
    set :bind, '0.0.0.0'
    set :port, 3000

    enable :logging
  end
end
