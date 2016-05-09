require "serverspec"

set :backend, :exec

describe "Apache Kafka Formula" do


  describe service("kafka-broker") do
    it { should be_enabled }
    it { should be_running }
  end

  portlist = [9092, 2181]
  for _port in portlist do
    describe port(_port) do
      it { should be_listening }
    end
  end

end
