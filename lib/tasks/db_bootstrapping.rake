require 'rbconfig'
require_relative '../utils/snapshot_helpers.rb'

include Utils::SnapshotHelpers

namespace :dgidb do

  data_submodule_path = File.join(Rails.root, 'data')
  data_file = File.join(data_submodule_path, 'data.sql')
  version_file = File.join(Rails.root, 'VERSION')
  database_name = Rails.configuration.database_configuration[Rails.env]['database']
  host = Rails.configuration.database_configuration[Rails.env]['host']

  desc 'Remove a source from the database given the source_db_name'
  task :remove_source, [:source_db_name] => :environment do |_, args|
    Utils::Database.delete_source(args[:source_db_name])
  end

  desc 'set up path for macs running Postgres.app'
  task :setup_path do
    #special case for macs running Postgres.app
    if RbConfig::CONFIG['host_os'] =~ /darwin/ && File.exist?( '/Applications/Postgres.app' )
      puts 'Found Postgres.app'
      ENV['PATH'] = "/Applications/Postgres.app/Contents/Versions/9.4/bin:#{ENV['PATH']}"
    end

    # MacPorts Handling
    macports_postgres = Dir.glob( '/opt/local/lib/postgresql*/bin')
    if RbConfig::CONFIG['host_os'] =~ /darwin/ && macports_postgres.any?
      macports_postgres_path = macports_postgres.last
      macports_postgres_version = File.basename(File.dirname(macports_postgres_path))
      puts "Found MacPorts #{macports_postgres_version}"
      ENV['PATH'] = "#{macports_postgres_path}:#{ENV['PATH']}"
    end

    # Homebrew Handling (TODO)
  end

  desc 'create a dump of the current local database'
  task dump_local: [:setup_path] do
    system "pg_dump -T schema_migrations -E UTF8 -a -f #{data_file} -h #{host} #{database_name}"
  end

  desc 'load the source controlled db dump and schema into the local db, blowing away what is currently there'
  task load_local: ['setup_path', 'db:drop', 'db:create', 'db:structure:load'] do
    begin
      update_data_submodule
    rescue
      puts 'Unable to access the git repo, you are probably outside our firewall.'
      puts 'Downloading the data dump manually.'
      download_data_dump(data_file)
    end
    system "psql -h #{host} -d #{database_name} -f #{data_file}"
  end

  desc 'create a new data snapshot'
  task :create_snapshot, [:message, :version_type] do |t, args|
    args.with_defaults(version_type: :patch)
    raise 'You must supply a commit message!' unless args[:message]
    Rake::Task['dgidb:dump_local'].execute
    in_git_stash do
      pull_latest
      new_version = update_version(version_file, args[:version_type].to_sym)
      commit_db_update(data_submodule_path, data_file, args[:message])
      commit_data_submodule_update(args[:message], data_submodule_path, version_file)
      create_tag(new_version)
      push_changes
    end
  end

end
