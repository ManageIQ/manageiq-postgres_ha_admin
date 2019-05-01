require 'pg'
require 'pg/dsn_parser'

module ManageIQ
module PostgresHaAdmin
  class LogicalReplicationConfigHandler < ConfigHandler
    attr_reader :subscription, :conn_info

    def initialize(options = {})
      @subscription = options[:subscription]
      @conn_info    = options[:conn_info]
    end

    def name
      "Logical Replication subscription #{subscription} Config Handler"
    end

    def read
      conn = PG::Connection.open(@conn_info)
      dsn = conn.exec_params(<<~SQL, [@subscription]).first["subconninfo"]
        SELECT subconninfo
        FROM pg_subscription
        WHERE subname = $1
      SQL
      PG::DSNParser.new.parse(dsn)
    end

    def write(_params)
      # Nothing to do here as the expectation is that the user will 
      # remove and re-add the subscription in the after failover callback
    end
  end
end
end
