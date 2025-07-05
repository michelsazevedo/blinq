ENV['RAKE_ENV'] ||= 'development'

require 'rake'
require './config/sequeldb'

namespace :db do
  desc 'setup database (migrate + seed)'
  task :setup => [:migrate, :seed]

  desc 'migrates database'
  task :migrate, [:version] do |t, args|
    require 'sequel/core'

    Sequel.extension :migration

    version = args[:version].to_i if args[:version]

    SequelDb.sequel_instance_exec do |db|
      Sequel::Migrator.run(db, './db/migrations', target: version)
    end
  end

  desc 'seeds database'
  task :seed do
    require './db/seeds'
  end
end
