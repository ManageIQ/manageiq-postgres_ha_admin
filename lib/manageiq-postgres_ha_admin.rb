require 'manageiq/postgres_ha_admin/version'

require 'manageiq/postgres_ha_admin/logging'
require 'manageiq/postgres_ha_admin/null_logger'

require 'manageiq/postgres_ha_admin/server_store'
require 'manageiq/postgres_ha_admin/failover_monitor'

require 'manageiq/postgres_ha_admin/config_handler'
require 'manageiq/postgres_ha_admin/config_handler/rails_config_handler'

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
