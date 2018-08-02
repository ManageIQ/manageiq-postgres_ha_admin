require 'active_support/all'
require 'pg'
require 'linux_admin'

module ManageIQ
module PostgresHaAdmin
  class FailoverMonitor
    include Logging

    FAILOVER_ATTEMPTS = 10
    DB_CHECK_FREQUENCY = 300
    FAILOVER_CHECK_FREQUENCY = 60
    attr_accessor :failover_attempts, :db_check_frequency, :failover_check_frequency

    def initialize(config_path = "")
      initialize_settings(config_path)
    end

    def add_handler(handler)
      @config_handlers ||= []
      @config_handlers << [handler, ServerStore.new]
    end

    def monitor
      @config_handlers.each do |handler, server_store|
        begin
          connection = pg_connection(handler.read)
          if connection
            server_store.update_servers(connection)
            connection.finish
            next
          end

          logger.error("Primary Database is not available for #{handler.name}. Starting to execute failover...")
          handler.do_before_failover

          new_conn_info = execute_failover(handler, server_store)
          if new_conn_info
            handler.do_after_failover(new_conn_info)
          else
            logger.error("Failover failed")
          end
        rescue => e
          logger.error("Received #{e.class} error while monitoring #{handler.name}: #{e.message}")
          logger.error(e.backtrace)
        end
      end
    end

    def monitor_loop
      loop do
        begin
          monitor
        rescue => err
          logger.error("#{err.class}: #{err}")
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

    def initialize_settings(ha_admin_yml_file)
      ha_admin_yml = {}
      begin
        ha_admin_yml = YAML.load_file(ha_admin_yml_file) if File.exist?(ha_admin_yml_file)
      rescue SystemCallError, IOError => err
        logger.error("#{err.class}: #{err}")
        logger.info("File not loaded: #{ha_admin_yml_file}. Default settings for failover will be used.")
      end
      @failover_attempts = ha_admin_yml['failover_attempts'] || FAILOVER_ATTEMPTS
      @db_check_frequency = ha_admin_yml['db_check_frequency'] || DB_CHECK_FREQUENCY
      @failover_check_frequency = ha_admin_yml['failover_check_frequency'] || FAILOVER_CHECK_FREQUENCY
      logger.info("FAILOVER_ATTEMPTS=#{@failover_attempts} DB_CHECK_FREQUENCY=#{@db_check_frequency} FAILOVER_CHECK_FREQUENCY=#{@failover_check_frequency}")
    end

    def execute_failover(handler, server_store)
      failover_attempts.times do
        with_each_standby_connection(handler, server_store) do |connection, params|
          next if database_in_recovery?(connection)
          next unless server_store.host_is_primary?(params[:host], connection)
          logger.info("Failing over to server using conninfo: #{params.reject { |k, _v| k == :password }}")
          server_store.update_servers(connection)
          handler.write(params)
          return params
        end
        sleep(failover_check_frequency)
      end
      false
    end

    def with_each_standby_connection(handler, server_store)
      active_servers_conninfo(handler, server_store).each do |params|
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
      logger.error("Failed to establish PG connection: #{e.message}")
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
