require 'manageiq/postgres_ha_admin/version'

require 'manageiq/postgres_ha_admin/logging'
require 'manageiq/postgres_ha_admin/null_logger'

require 'manageiq/postgres_ha_admin/database_yml'
require 'manageiq/postgres_ha_admin/failover_databases'
require 'manageiq/postgres_ha_admin/failover_monitor'

module ManageIQ
  module PostgresHaAdmin
    class << self
      attr_writer :logger
    end

    def self.logger
      @logger ||= NullLogger.new
    end
  end
end
