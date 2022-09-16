module ManageIQ
module PostgresHaAdmin
  module Logging
    def logger
      ManageIQ::PostgresHaAdmin.logger
    end

    def log_prefix(method)
      "(PostgresHaAdmin##{method})"
    end
  end
end
end
