# frozen_string_literal: true

require 'sequel'

# Sequel
class SequelDb
  class << self
    def establish_connection!
      conn
    end

    def sequel_instance_exec(&block)
      yield conn
    end

    private

    def conn
      mutex.synchronize do
        @conn ||= Sequel.connect(connection_string, max_connections: ENV.fetch('SEQUEL_POOL', 8)).tap do |db|
          db.run('PRAGMA journal_mode=WAL;')
          at_exit do
            db.disconnect
          end
        end
      end
    end

    def connection_string
      'sqlite://db/blinq.sqlite3'
    end

    def mutex
      @mutex ||= Mutex.new
    end
  end
end
