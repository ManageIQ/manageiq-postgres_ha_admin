require 'pg'
require 'pg/dsn_parser'

module ManageIQ
module PostgresHaAdmin
  class PglogicalConfigHandler < ConfigHandler
    attr_reader :subscription, :conn_info

    def initialize(options = {})
      @subscription = options[:subscription]
      @conn_info    = options[:conn_info]
    end

    def name
      "pglogical subscription #{subscription} Config Handler"
    end

    def read
      conn = PG::Connection.open(@conn_info)
      dsn = conn.exec_params(<<~SQL, [@subscription]).first["if_dsn"]
        SELECT if_dsn
        FROM pglogical.subscription s
        JOIN pglogical.node_interface i
          ON s.sub_origin_if = i.if_id
        WHERE s.sub_name = $1
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
