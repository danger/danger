require "danger/services/home_keeper"

describe Danger::HomeKeeper do
  describe ".check_home_permission!" do
    context "home directory is not writable" do
      it "raise error and mentioned in error message" do
        allow(File).to receive(:writable?) { false }

        expect { described_class.check_home_permission! }.to raise_error(
          Danger::HomeDirectoyError,
          /is not writable/
        )
      end
    end

    context "home directory isn't a directory" do
      it "raise error and mentioned in error message" do
        allow(File).to receive(:directory?) { false }

        expect { described_class.check_home_permission! }.to raise_error(
          Danger::HomeDirectoyError,
          /is not a directory/
        )
      end
    end

    context "home directory is writable and a directory" do
      it "works" do
        allow(File).to receive(:writable?) { true }
        allow(File).to receive(:directory?) { true }

        expect { described_class.check_home_permission! }.not_to raise_error
      end
    end
  end

  describe ".create_latest_version_file!" do
    it "writes a version string to danger file" do
      allow(Danger::RubyGemsClient).to receive(:get_latest_danger_version) { "3.1.1" }

      expect(IO).to receive(:write)

      described_class.create_latest_version_file!
    end
  end

  describe ".is_danger_outdated?" do
    context "with dummy version" do
      it "returns false" do
        allow(IO).to receive(:read) { "0.0.0" }

        result = described_class.is_danger_outdated?

        expect(result).to be false
      end
    end

    context "when latest version > current version" do
      it "returns true" do
        allow(IO).to receive(:read) { "10.0.0" }
        stub_const("Danger::VERSION", "1.0.0")

        result = described_class.is_danger_outdated?

        expect(result).to be false
      end
    end

    context "when latest version < current version" do
      it "returns false" do
        allow(IO).to receive(:read) { "1.0.0" }
        stub_const("Danger::VERSION", "10.0.0")

        result = described_class.is_danger_outdated?

        expect(result).to be false
      end
    end
  end
end
