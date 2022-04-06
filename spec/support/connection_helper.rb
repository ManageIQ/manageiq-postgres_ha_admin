module ConnectionHelper
  def self.connection_for(dbname)
    require "pg"

    options = {
      :host     => ENV["PGHOST"],
      :user     => ENV.fetch("PGUSER", "root"),
      :password => ENV.fetch("PGPASSWORD", "smartvm"),
      :dbname   => dbname
    }.compact

    PG::Connection.new(options)
  end
end
