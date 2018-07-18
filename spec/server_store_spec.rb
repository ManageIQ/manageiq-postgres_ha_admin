describe ManageIQ::PostgresHaAdmin::ServerStore do
  describe "#active_databases_conninfo_hash" do
    it "returns a list of active databases connection info" do
      expected = [
        {:host => '203.0.113.1', :user => 'root', :dbname => 'vmdb_test'},
        {:host => '203.0.113.2', :user => 'root', :dbname => 'vmdb_test'}
      ]
      subject.instance_variable_set(:@servers, initial_db_list)
      expect(subject.active_databases_conninfo_hash).to contain_exactly(*expected)
    end
  end

  describe "#active_databases" do
    it "return list of active databases saved in 'config/failover_databases.yml'" do
      subject.instance_variable_set(:@servers, initial_db_list)
      expect(subject.active_databases).to contain_exactly(
        {:type => 'primary', :active => true, :host => '203.0.113.1', :user => 'root', :dbname => 'vmdb_test'},
        {:type => 'standby', :active => true, :host => '203.0.113.2', :user => 'root', :dbname => 'vmdb_test'})
    end
  end

  context "accessing database" do
    after do
      if @connection
        @connection.exec("ROLLBACK")
        @connection.finish
      end
    end

    before do
      # @connection = PG::Connection.open(:dbname => 'vmdb_test')
      begin
        @connection = PG::Connection.open(:dbname => 'travis', :user => 'travis')
      rescue PG::ConnectionBad
        skip "travis database does not exist"
      end

      @connection.exec("START TRANSACTION")
      @connection.exec("CREATE SCHEMA repmgr")
      @connection.exec(<<-SQL)
        CREATE TABLE #{described_class::TABLE_NAME}  (
          type text NOT NULL,
          conninfo text NOT NULL,
          active boolean DEFAULT true NOT NULL
        )
      SQL

      @connection.exec(<<-SQL)
        INSERT INTO
          #{described_class::TABLE_NAME}(type, conninfo, active)
        VALUES
          ('primary', 'host=203.0.113.1 user=root dbname=vmdb_test', 'true'),
          ('standby', 'host=203.0.113.2 user=root dbname=vmdb_test', 'true'),
          ('standby', 'host=203.0.113.3 user=root dbname=vmdb_test', 'false'),
          ('primary', 'host=203.0.113.5 user=root dbname=vmdb_test', 'false')
      SQL
    end

    describe "#update_failover_yml" do
      it "updates the servers list" do
        subject.update_failover_yml(@connection)

        expect(subject.servers).to eq initial_db_list

        add_new_record

        subject.update_failover_yml(@connection)
        expect(subject.servers).to eq new_db_list
      end
    end

    describe "#host_is_repmgr_primary?" do
      it "return true if supplied connection established with primary database" do
        expect(subject.host_is_repmgr_primary?('203.0.113.1', @connection)).to be true
      end

      it "return false if supplied connection established with not active standby database" do
        expect(subject.host_is_repmgr_primary?('203.0.113.3', @connection)).to be false
      end

      it "return false if supplied connection established with active standby database" do
        expect(subject.host_is_repmgr_primary?('203.0.113.2', @connection)).to be false
      end

      it "return false if supplied connection established with not active primary database" do
        expect(subject.host_is_repmgr_primary?('203.0.113.5', @connection)).to be false
      end
    end
  end

  def initial_db_list
    arr = []
    arr << {:type => 'primary', :active => true, :host => '203.0.113.1', :user => 'root', :dbname => 'vmdb_test'}
    arr << {:type => 'standby', :active => true, :host => '203.0.113.2', :user => 'root', :dbname => 'vmdb_test'}
    arr << {:type => 'standby', :active => false, :host => '203.0.113.3', :user => 'root', :dbname => 'vmdb_test'}
    arr << {:type => 'primary', :active => false, :host => '203.0.113.5', :user => 'root', :dbname => 'vmdb_test'}
    arr
  end

  def new_db_list
    initial_db_list << {:type => 'standby', :active => true, :host => '203.0.113.4',
                        :user => 'root', :dbname => 'some_db'}
  end

  def add_new_record
    @connection.exec(<<-SQL)
      INSERT INTO
        #{described_class::TABLE_NAME}(type, conninfo, active)
      VALUES
        ('standby', 'host=203.0.113.4 user=root dbname=some_db', 'true')
    SQL
  end
end
