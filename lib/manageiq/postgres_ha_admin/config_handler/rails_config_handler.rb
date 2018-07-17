require 'active_support/all'
require 'util/miq-password'
require 'fileutils'

module ManageIQ
module PostgresHaAdmin
  class RailsConfigHandler < ConfigHandler
    attr_reader :environment, :file_path

    def initialize(options = {})
      @file_path   = options[:file_path]
      @environment = options[:environment]
    end

    def read
      rails_params_to_pg(YAML.load_file(file_path)[environment])
    end

    def write(params)
      db_yml = YAML.load_file(file_path)
      db_yml[environment].merge!(pg_parameters_to_rails(params))
      remove_empty(db_yml[environment])

      new_name = "#{file_path}_#{Time.current.strftime("%d-%B-%Y_%H.%M.%S")}"
      FileUtils.copy(file_path, new_name)
      begin
        File.write(file_path, db_yml.to_yaml)
      rescue
        FileUtils.mv(new_name, file_path)
        raise
      end
      new_name
    end

    private

    def rails_params_to_pg(params)
      pg_params = {}
      pg_params[:dbname] = params['database']
      pg_params[:user] = params['username']
      pg_params[:port] = params['port']
      pg_params[:host] = params['host']
      pg_params[:password] = MiqPassword.try_decrypt(params['password'])
      remove_empty(pg_params)
    end

    def pg_parameters_to_rails(pg_params)
      params = {}
      params['username'] = pg_params[:user]
      params['database'] = pg_params[:dbname]
      params['port'] = pg_params[:port]
      params['host'] = pg_params[:host]
      remove_empty(params)
    end

    def remove_empty(hash)
      hash.delete_if { |_k, v| v.nil? || v.to_s.strip.empty? }
    end
  end
end
end
