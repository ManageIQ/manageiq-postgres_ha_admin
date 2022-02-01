describe ManageIQ::PostgresHaAdmin::ConfigHandler do
  describe "#before_failover" do
    it "raises an ArgumentError if called without a block" do
      expect { subject.before_failover }.to raise_error(ArgumentError)
    end
  end

  describe "#after_failover" do
    it "raises an ArgumentError if called without a block" do
      expect { subject.after_failover }.to raise_error(ArgumentError)
    end
  end

  describe "#do_before_failover" do
    it "runs with no callback registered" do
      subject.do_before_failover
    end

    it "calls the registered failover" do
      before_failover_obj = double("before_failover_object")

      subject.before_failover do
        before_failover_obj.before_failover_things
      end

      expect(before_failover_obj).to receive(:before_failover_things)
      subject.do_before_failover
    end
  end

  describe "#do_after_failover" do
    it "runs with no callback registered" do
      subject.do_after_failover(:host => "db.example.com")
    end

    it "calls the registered failover" do
      after_failover_obj = double("after_failover_object")

      subject.after_failover do |new_conninfo|
        after_failover_obj.after_failover_things(new_conninfo)
      end

      expect(after_failover_obj).to receive(:after_failover_things).with({:host => "db.example.com"})
      subject.do_after_failover({:host => "db.example.com"})
    end
  end
end
