module ManageIQ
module PostgresHaAdmin
  class ConfigHandler
    attr_reader :file_path

    def initialize(file_path, _options = {})
      @file_path = file_path
    end

    def read
      raise NotImplementedError
    end

    def write(_conninfo)
      raise NotImplementedError
    end
  end
end
end
