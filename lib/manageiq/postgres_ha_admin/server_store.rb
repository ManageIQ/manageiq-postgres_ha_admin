require 'active_support/all'
require 'pg'
require 'pg/dsn_parser'

module ManageIQ
module PostgresHaAdmin
  class ServerStore
    include Logging

    TABLE_NAME = "repmgr.nodes".freeze

    attr_reader :servers

    def initialize
      @servers = []
    end

    def connection_info_list
      valid_keys = PG::Connection.conndefaults_hash.keys + [:requiressl]
      servers.map! do |db_info|
        db_info.keep_if { |k, _v| valid_keys.include?(k) }
      end
    end

    def update_servers(connection)
      new_servers = query_repmgr(connection)
      if servers_changed?(new_servers)
        logger.info("#{log_prefix(__callee__)} Updating servers cache to #{new_servers}")
        @servers = new_servers
      end
    rescue IOError => err
      logger.error("#{log_prefix(__callee__)} #{err.class}: #{err}")
      logger.error(err.backtrace.join("\n"))
    end

    def host_is_primary?(host, connection)
      query_repmgr(connection).each do |record|
        if record[:host] == host && record[:type] == 'primary'
          return true
        end
      end
      false
    end

    private

    def servers_changed?(new_servers)
      ((servers - new_servers) + (new_servers - servers)).any?
    end

    def query_repmgr(connection)
      return [] unless table_exists?(connection, TABLE_NAME)
      result = []
      db_result = connection.exec("SELECT type, conninfo, active FROM #{TABLE_NAME} WHERE active")
      db_result.map_types!(PG::BasicTypeMapForResults.new(connection)).each do |record|
        dsn = PG::DSNParser.parse(record.delete("conninfo"))
        result << record.symbolize_keys.merge(dsn)
      end
      db_result.clear
      result
    rescue PG::Error => err
      logger.error("#{log_prefix(__callee__)} #{err.class}: #{err}")
      logger.error(err.backtrace.join("\n"))
      result
    end

    def table_exists?(connection, table_name)
      result = connection.exec("SELECT to_regclass('#{table_name}')").first
      !result['to_regclass'].nil?
    end
  end
end
end
