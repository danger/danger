require "danger/services/home_keeper"

describe Danger::HomeKeeper do
  describe ".create_latest_version_file!" do
    context "when has home permission" do
      before { allow(described_class).to receive(:home_permission?) { true } }

      it "writes a version string to danger file" do
        allow(Danger::RubyGemsClient).to receive(:latest_danger_version) { "3.1.1" }

        expect(IO).to receive(:write)

        described_class.create_latest_version_file!
      end
    end

    context "when doesn't has home permission" do
      before { allow(described_class).to receive(:home_permission?) { false } }

      it "writes a version string to danger file" do
        expect(IO).not_to receive(:write)

        described_class.create_latest_version_file!
      end
    end
  end

  describe ".danger_outdated?" do
    context "with dummy version" do
      it "returns false" do
        allow(IO).to receive(:read) { "0.0.0" }

        result = described_class.danger_outdated?

        expect(result).to be false
      end
    end

    context "when latest version > current version" do
      it "returns true" do
        allow(IO).to receive(:read) { "10.0.0" }
        stub_const("Danger::VERSION", "1.0.0")

        result = described_class.danger_outdated?

        expect(result).to be false
      end
    end

    context "when latest version < current version" do
      it "returns false" do
        allow(IO).to receive(:read) { "1.0.0" }
        stub_const("Danger::VERSION", "10.0.0")

        result = described_class.danger_outdated?

        expect(result).to be false
      end
    end
  end
end
