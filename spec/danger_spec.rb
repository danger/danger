require "danger/clients/rubygems_client"

RSpec.describe Danger do
  context "when installed danger is outdated and an error is raised" do
    before do
      stub_const("Danger::VERSION", "1.0.0")
      allow(Danger::RubyGemsClient).to receive(:latest_danger_version) { "2.0.0" }
    end

    it "prints an upgrade message" do
      message = "exception message"
      path = "path"
      exception = StandardError.new("error message")
      contents = "contents"

      expect do
        raise Danger::DSLError.new(message, path, exception.backtrace, contents)
      end.to raise_error(
        Danger::DSLError,
        /. Updating the Danger gem might fix the issue. Your Danger version: 1.0.0, latest Danger version: 2.0.0/
      )
    end
  end

  describe ".gem_path" do
    context "when danger gem found" do
      it "returns danger gem path" do
        result = Danger.gem_path

        expect(result).to match(/danger/i)
      end
    end

    context "when danger gem folder not found" do
      it "raises an error" do
        allow(Gem::Specification).to receive(:find_all_by_name) { [] }

        expect { Danger.gem_path }.to raise_error("Couldn't find gem directory for 'danger'")
      end
    end
  end

  describe ".danger_outdated?" do
    it "latest danger > local danger version" do
      allow(Danger::RubyGemsClient).to receive(:latest_danger_version) { "2.0.0" }
      stub_const("Danger::VERSION", "1.0.0")

      result = Danger.danger_outdated?

      expect(result).to eq "2.0.0"
    end

    it "latest danger < local danger version" do
      allow(Danger::RubyGemsClient).to receive(:latest_danger_version) { "1.0.0" }
      stub_const("Danger::VERSION", "2.0.0")

      result = Danger.danger_outdated?

      expect(result).to be false
    end
  end
end
