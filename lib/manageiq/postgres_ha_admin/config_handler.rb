module ManageIQ
module PostgresHaAdmin
  class ConfigHandler
    def read
      raise NotImplementedError
    end

    def write(_conninfo)
      raise NotImplementedError
    end
  end
end
end
