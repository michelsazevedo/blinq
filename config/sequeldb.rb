# frozen_string_literal: true

require 'sequel'

# Sequel
class SequelDb
  class << self
    def establish_connection!
      connect!
    end

    def sequel_instance_exec(&block)
      yield connect!
    end

    private

    def connect!
      Sequel::Model.plugin :timestamps
      Sequel.connect(connection_string, max_connections: ENV.fetch("SEQUEL_POOL", 8)).tap do |db|
        at_exit do
          db.disconnect
        end
      end
    end

    def connection_string
      "sqlite://db/blend.sqlite3"
    end
  end
end
