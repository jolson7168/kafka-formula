require "serverspec"

set :backend, :exec

describe "Apache Kafka Formula - Mirror Maker" do


  describe service("kafka-mirror") do
    it { should be_enabled }
    it { should be_running }
  end

end
