module ManageIQ
module PostgresHaAdmin
  class ConfigHandler
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
      do_callback(@before_failover_cb)
    end

    def do_after_failover
      do_callback(@after_failover_cb)
    end

    private

    def do_callback(cb)
      cb&.call
    end
  end
end
end
