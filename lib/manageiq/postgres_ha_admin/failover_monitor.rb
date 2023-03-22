require 'active_support/all'
require 'pg'

module ManageIQ
module PostgresHaAdmin
  class FailoverMonitor
    include Logging

    FAILOVER_ATTEMPTS = 10
    DB_CHECK_FREQUENCY = 120
    FAILOVER_CHECK_FREQUENCY = 60
    attr_accessor :failover_attempts, :db_check_frequency, :failover_check_frequency
    attr_reader :config_handlers

    def initialize(config_path = "")
      initialize_settings(config_path)
      @config_handlers = []
    end

    def add_handler(handler)
      @config_handlers << [handler, ServerStore.new]
    end

    def monitor
      config_handlers.each do |handler, server_store|
        begin
          connection = pg_connection(handler.read)
          if connection
            server_store.update_servers(connection, handler.name)
            connection.finish
            next
          end

          log_settings
          server_store.log_current_server_store(handler.name)
          logger.error("#{log_prefix(__callee__)} Primary Database is not available for #{handler.name}. Starting to execute failover...")
          handler.do_before_failover

          new_conn_info = execute_failover(handler, server_store)

          # Upon success, we pass a connection hash
          handler.do_after_failover(new_conn_info) if new_conn_info
        rescue => e
          logger.error("#{log_prefix(__callee__)} Received #{e.class} error while monitoring #{handler.name}: #{e.message}")
          logger.error(e.backtrace)
        end
      end
    end

    def monitor_loop
      loop do
        begin
          monitor
        rescue => err
          logger.error("#{log_prefix(__callee__)} #{err.class}: #{err}")
          logger.error(err.backtrace.join("\n"))
        end
        sleep(db_check_frequency)
      end
    end

    def active_servers_conninfo(handler, server_store)
      servers = server_store.connection_info_list
      current_params = handler.read
      servers.map! { |info| current_params.merge(info) }
    end

    private

    def log_settings
      logger.info("#{log_prefix(__callee__)} Current HA settings: FAILOVER_ATTEMPTS=#{@failover_attempts} DB_CHECK_FREQUENCY=#{@db_check_frequency} FAILOVER_CHECK_FREQUENCY=#{@failover_check_frequency}")
    end

    def initialize_settings(ha_admin_yml_file)
      ha_admin_yml = {}
      begin
        ha_admin_yml = YAML.load_file(ha_admin_yml_file) if File.exist?(ha_admin_yml_file)
      rescue SystemCallError, IOError => err
        logger.error("#{log_prefix(__callee__)} #{err.class}: #{err}")
        logger.info("#{log_prefix(__callee__)} File not loaded: #{ha_admin_yml_file}. Default settings for failover will be used.")
      end
      @failover_attempts = ha_admin_yml['failover_attempts'] || FAILOVER_ATTEMPTS
      @db_check_frequency = ha_admin_yml['db_check_frequency'] || DB_CHECK_FREQUENCY
      @failover_check_frequency = ha_admin_yml['failover_check_frequency'] || FAILOVER_CHECK_FREQUENCY
      log_settings
    end

    def any_known_standby?(handler, server_store)
      current_host = handler.read[:host]
      server_store.servers.any? do |server|
        server[:host] != current_host && server[:type] == "standby"
      end
    end

    def execute_failover(handler, server_store)
      # TODO: Instead of returning false, we should raise:
      # "No active standby"
      # "Standby in recovery"
      # "Exhausted all failover retry attempts" exceptions
      unless any_known_standby?(handler, server_store)
        logger.error("#{log_prefix(__callee__)} Cannot attempt failover without a known active standby for #{handler.name}.  Please verify the database.yml and ensure the database is started.")
        return false
      end

      failover_attempts.times do
        with_each_standby_connection(handler, server_store) do |connection, params|
          next if database_in_recovery?(connection)
          next unless server_store.host_is_primary?(params[:host], connection)
          logger.info("#{log_prefix(__callee__)} Failing over for #{handler.name} to server using conninfo: #{server_store.sanitized_connection_parameters(params)}")
          server_store.update_servers(connection, handler.name)
          handler.write(params)
          return params
        end
        sleep(failover_check_frequency)
      end
      logger.error("#{log_prefix(__callee__)} Failover failed for #{handler.name}")
      false
    end

    def with_each_standby_connection(handler, server_store)
      active_servers_conninfo(handler, server_store).each do |params|
        logger.info("#{log_prefix(__callee__)} Checking active server for #{handler.name} using conninfo: #{server_store.sanitized_connection_parameters(params)}")
        connection = pg_connection(params)
        next if connection.nil?
        begin
          yield connection, params
        ensure
          connection.finish
        end
      end
    end

    def pg_connection(params)
      PG::Connection.open(params)
    rescue PG::Error => e
      logger.error("#{log_prefix(__callee__)} Failed to establish PG connection: #{e.message}")
      nil
    end

    # Checks if postgres database is in recovery mode
    #
    # @param pg_connection [PG::Connection] established pg connection
    # @return [Boolean] true if database in recovery mode
    def database_in_recovery?(pg_connection)
      pg_connection.exec("SELECT pg_catalog.pg_is_in_recovery()") do |db_result|
        result = db_result.map_types!(PG::BasicTypeMapForResults.new(pg_connection)).first
        result['pg_is_in_recovery']
      end
    end
  end
end
end
