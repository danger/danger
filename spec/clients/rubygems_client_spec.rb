require "danger/clients/rubygems_client"

RSpec.describe Danger::RubyGemsClient do
  describe ".latest_danger_version" do
    context "rubygems.org is operational" do
      it "returns latest danger version" do
        latest_version_json = IO.read("spec/fixtures/rubygems_api/api_v1_versions_danger_latest.json")
        allow(Faraday).to receive_message_chain(:get, :body) { latest_version_json }

        result = described_class.latest_danger_version

        expect(result).to eq "3.1.1"
      end
    end

    context "user does not have network connection" do
      it "returns dummy version" do
        allow(Faraday).to receive_message_chain(:get, :body) { raise Faraday::ConnectionFailed }

        result = described_class.latest_danger_version

        expect(result).to eq described_class.const_get(:DUMMY_VERSION)
      end
    end

    context "rubygems.org is not operational" do
      it "returns dummy version" do
        allow(Faraday).to receive_message_chain(:get, :body) { raise "RubyGems.org is down 🔥" }

        result = described_class.latest_danger_version

        expect(result).to eq described_class.const_get(:DUMMY_VERSION)
      end
    end

    context "rubygems.org returns wrong data" do
      it "returns dummy version" do
        allow(Faraday).to receive_message_chain(:get, :body) { ["", nil].sample }

        result = described_class.latest_danger_version

        expect(result).to eq described_class.const_get(:DUMMY_VERSION)
      end
    end
  end
end
