describe ManageIQ::PostgresHaAdmin::FailoverMonitor do
  let(:config_handler)  { double('ConfigHandler', :name => "Test config handler") }
  let(:config_handler2) { double('ConfigHandler2', :name => "Other config handler") }
  let(:server_store)    { double('ServerStore') }
  let(:server_store2)   { double('ServerStore2') }
  let(:server_store)    { double('ServerStore',  :servers => [{:type => 'primary'}, {:type => 'standby'}]) }
  let(:server_store2)   { double('ServerStore2', :servers => [{:type => 'primary'}, {:type => 'standby'}]) }

  before do
    allow(ManageIQ::PostgresHaAdmin::ServerStore).to receive(:new).and_return(server_store, server_store2)
  end

  let(:connection) do
    conn = double("PGConnection")
    allow(conn).to receive(:finish)
    conn
  end

  describe "#initialize" do
    it "override default failover settings with settings loaded from provided config file" do
      require 'tempfile'
      ha_admin_yml_file = Tempfile.new('ha_admin.yml')
      yml_data = YAML.load(<<-DOC)
---
failover_attempts: 20
      DOC

      File.write(ha_admin_yml_file.path, yml_data.to_yaml)
      monitor_with_settings = described_class.new(ha_admin_yml_file.path)
      ha_admin_yml_file.close(true)

      expect(described_class::FAILOVER_ATTEMPTS).not_to eq 20
      expect(monitor_with_settings.failover_attempts).to eq 20
      expect(monitor_with_settings.db_check_frequency).to eq described_class::DB_CHECK_FREQUENCY
    end

    it "uses default failover settings if config file is not provided" do
      expect(subject.failover_attempts).to eq described_class::FAILOVER_ATTEMPTS
      expect(subject.db_check_frequency).to eq described_class::DB_CHECK_FREQUENCY
      expect(subject.failover_check_frequency).to eq described_class::FAILOVER_CHECK_FREQUENCY
    end
  end

  describe "#any_known_standby?" do
    let(:standby_handler) { double(:name => "standby_test", :read => {:host => '203.0.113.1'}) }
    let(:server_list) do
      [
        {:type => 'primary', :active => true, :host => '203.0.113.1', :user => 'root', :dbname => 'vmdb_test'},
        {:type => 'standby', :active => true, :host => '203.0.113.2', :user => 'root', :dbname => 'vmdb_test'}
      ]
    end

    it "is true with a standby that's not the current database" do
      expect(subject.send(:any_known_standby?, standby_handler, double(:servers => server_list))).to be_truthy
    end

    it "is false with 2 primaries, no standby" do
      server_list.last[:type] = 'primary'
      expect(subject.send(:any_known_standby?, standby_handler, double(:servers => server_list))).to be_falsy
    end

    it "is false with no known primary or standby" do
      server_list = []
      expect(subject.send(:any_known_standby?, standby_handler, double(:servers => server_list))).to be_falsy
    end

    it "is false with only standby as current database" do
      server_list.last[:host] = '203.0.113.1'
      expect(subject.send(:any_known_standby?, standby_handler, double(:servers => server_list))).to be_falsy
    end
  end

  describe "#monitor" do
    before do
      params = {
        :host     => 'host.example.com',
        :user     => 'root',
        :password => 'password'
      }
      allow(config_handler).to receive(:read).and_return(params)
      subject.add_handler(config_handler)
    end

    context "primary database is accessable" do
      before do
        allow(PG::Connection).to receive(:open).and_return(connection)
      end

      it "updates server store" do
        expect(server_store).to receive(:update_servers)
        subject.monitor
      end

      it "monitors multiple handlers" do
        subject.add_handler(config_handler2)

        expect(server_store).to receive(:update_servers)
        expect(server_store2).to receive(:update_servers)
        expect(config_handler2).to receive(:read).and_return(:host => "other.example.com", :user => "me", :password => "notpassword")
        subject.monitor
      end

      it "monitors multiple handlers even if one raises" do
        subject.add_handler(config_handler2)

        expect(server_store).to receive(:update_servers).and_raise(RuntimeError)
        expect(server_store2).to receive(:update_servers)
        expect(config_handler2).to receive(:read).and_return(:host => "other.example.com", :user => "me", :password => "notpassword")
        subject.monitor
      end

      it "does not execute before failover callback and does not execute failover" do
        expect(server_store).to receive(:update_servers)
        expect(subject).not_to receive(:execute_failover)
        expect(config_handler).not_to receive(:do_before_failover)

        subject.monitor
      end
    end

    context "primary database is not accessable" do
      before do
        allow(PG::Connection).to receive(:open).and_return(nil, connection, connection)
        stub_monitor_constants
      end

      it "calls the before failover callback before failover attempt" do
        conn_info = {:dbname => "blah", :user => "root"}
        expect(config_handler).to receive(:do_before_failover).ordered
        expect(subject).to receive(:execute_failover).ordered.and_return(conn_info)
        expect(config_handler).to receive(:do_after_failover).ordered.with(conn_info)
        subject.monitor
      end

      it "does not update config handler and server store if all standby DBs are in recovery mode" do
        failover_not_executed
        expect(subject).to receive(:database_in_recovery?).and_return(true, true, true).ordered
        subject.monitor
      end

      it "does not update config handler and server store if there is no master database avaiable" do
        failover_not_executed
        expect(subject).to receive(:database_in_recovery?).and_return(false, false, false).ordered
        expect(server_store).to receive(:host_is_primary?).and_return(false, false, false).ordered
        subject.monitor
      end

      it "updates config handler and server store and runs callbacks if new primary db available" do
        failover_executed
        expect(subject).to receive(:database_in_recovery?).and_return(false)
        expect(server_store).to receive(:host_is_primary?).and_return(true)
        subject.monitor
      end
    end
  end

  describe "#active_servers_conninfo" do
    it "merges settings from config handler and server store" do
      active_servers_conninfo = [
        {:host => 'failover_host.example.com'},
        {:host => 'failover_host2.example.com'}
      ]
      expected_conninfo = [
        {:host => 'failover_host.example.com', :password => 'mypassword'},
        {:host => 'failover_host2.example.com', :password => 'mypassword'}
      ]
      settings_from_config_handler = {:host => 'host.example.com', :password => 'mypassword'}
      expect(server_store).to receive(:connection_info_list).and_return(active_servers_conninfo)
      expect(config_handler).to receive(:read).and_return(settings_from_config_handler)
      expect(subject.active_servers_conninfo(config_handler, server_store)).to match_array(expected_conninfo)
    end
  end

  def failover_executed
    expect(config_handler).to receive(:do_before_failover)
    expect(server_store).to receive(:connection_info_list).and_return(active_databases_conninfo)
    expect(server_store).to receive(:update_servers)
    expect(config_handler).to receive(:write)
    expect(config_handler).to receive(:do_after_failover)
  end

  def failover_not_executed
    expect(config_handler).to receive(:do_before_failover)
    expect(server_store).to receive(:connection_info_list).and_return(active_databases_conninfo)
    expect(server_store).not_to receive(:update_servers)
    expect(config_handler).not_to receive(:write)
    expect(config_handler).to receive(:do_after_failover).never
  end

  def stub_monitor_constants
    subject.instance_variable_set(:@failover_attempts, 1)
    subject.instance_variable_set(:@failover_check_frequency, 0)
  end

  def active_databases_conninfo
    [{}, {}, {}]
  end

  context "private" do
    describe "#database_in_recovery?" do
      before do
        @connection = ConnectionHelper.connection_for('vmdb_test')
      end

      after do
        @connection.finish if @connection
      end

      it "returns false if postgres database not in recovery mode" do
        expect(subject.send(:database_in_recovery?, @connection)).to be false
      end
    end
  end
end
