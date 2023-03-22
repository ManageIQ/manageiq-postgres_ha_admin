describe ManageIQ::PostgresHaAdmin::ServerStore do
  describe "#connection_info_list" do
    it "returns a list of database connection info" do
      expected = [
        {:host => '203.0.113.1', :user => 'root', :dbname => 'vmdb_test'},
        {:host => '203.0.113.2', :user => 'root', :dbname => 'vmdb_test'}
      ]
      subject.instance_variable_set(:@servers, initial_db_list)
      expect(subject.connection_info_list).to contain_exactly(*expected)
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
      @connection = ConnectionHelper.connection_for('vmdb_test')
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

    describe "#update_servers" do
      it "updates the servers list" do
        subject.update_servers(@connection, "test handler")

        expect(subject.servers).to eq initial_db_list

        add_new_record

        subject.update_servers(@connection, "test handler")
        expect(subject.servers).to eq new_db_list
      end
    end

    describe "#host_is_primary?" do
      it "return true if supplied connection established with primary database" do
        expect(subject.host_is_primary?('203.0.113.1', @connection)).to be true
      end

      it "return false if supplied connection established with not active standby database" do
        expect(subject.host_is_primary?('203.0.113.3', @connection)).to be false
      end

      it "return false if supplied connection established with active standby database" do
        expect(subject.host_is_primary?('203.0.113.2', @connection)).to be false
      end

      it "return false if supplied connection established with not active primary database" do
        expect(subject.host_is_primary?('203.0.113.5', @connection)).to be false
      end
    end
  end

  def initial_db_list
    [
      {:type => 'primary', :active => true, :host => '203.0.113.1', :user => 'root', :dbname => 'vmdb_test'},
      {:type => 'standby', :active => true, :host => '203.0.113.2', :user => 'root', :dbname => 'vmdb_test'}
    ]
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
