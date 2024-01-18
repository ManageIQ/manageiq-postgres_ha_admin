require 'tempfile'

describe ManageIQ::PostgresHaAdmin::RailsConfigHandler do
  subject { described_class.new(:file_path => @yml_file.path, :environment => 'test') }

  before do
    @yml_file = Tempfile.new('database.yml')
    data = <<-DOC
---
base: &base
  username: user
  wait_timeout: 5
  port:
test: &test
  <<: *base
  pool: 3
  database: vmdb_test
DOC
    yml_data =
      if YAML.respond_to?(:safe_load)
        YAML.safe_load(data, :aliases => true)
      else
        YAML.load(data)
      end
    File.write(@yml_file.path, yml_data.to_yaml)
  end

  after do
    @yml_file.close(true)
  end

  describe "#name" do
    it "identifies the config handler by environment" do
      expect(subject.name).to eq("Rails test Config Handler")
    end
  end

  describe "#read" do
    it "returns pg connection parameters based on 'database.yml'" do
      params = subject.read
      expect(params).to eq(:dbname => 'vmdb_test', :user => 'user')
    end
  end

  describe "#write" do
    it "back-up existing 'database.yml'" do
      original_yml = YAML.load_file(@yml_file)

      new_name = subject.write(:any => 'any')

      expect(new_name.size).to be > @yml_file.path.size
      expect(YAML.load_file(new_name)).to eq original_yml
    end

    it "expect raise error and keep original 'database.yml' if updating database.yml failed" do
      original_yml = YAML.load_file(@yml_file)
      allow(File).to receive(:write).and_raise(StandardError)

      expect { subject.write(:any => 'any') }.to raise_error(StandardError)
      expect(YAML.load_file(@yml_file)).to eq original_yml
    end

    it "takes hash with 'pg style' parameters and override database.yml" do
      subject.write(:dbname => 'some_db', :host => "localhost", :port => '')
      yml = YAML.load_file(@yml_file)

      expect(yml['test']).to eq('database' => 'some_db', 'host' => 'localhost',
                                'username' => 'user', 'pool' => 3, 'wait_timeout' => 5)
    end
  end
end
