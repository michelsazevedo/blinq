# warn_indent: true
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
      Sequel.connect(connection_string)
    end

    def connection_string
      "sqlite://db/blend.sqlite3"
    end
  end
end
