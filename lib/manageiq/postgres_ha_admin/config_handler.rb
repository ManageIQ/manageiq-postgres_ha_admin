module ManageIQ
module PostgresHaAdmin
  class ConfigHandler
    def name
      "Config Handler"
    end

    def read
      raise NotImplementedError
    end

    def write(_conninfo)
      raise NotImplementedError
    end

    def before_failover(&block)
      raise ArgumentError, "A block is required to set the before failover callback" unless block_given?
      @before_failover_cb = block
    end

    def after_failover(&block)
      raise ArgumentError, "A block is required to set the after failover callback" unless block_given?
      @after_failover_cb = block
    end

    def do_before_failover
      @before_failover_cb&.call
    end

    def do_after_failover(new_primary_conn_info)
      @after_failover_cb&.call(new_primary_conn_info)
    end
  end
end
end
