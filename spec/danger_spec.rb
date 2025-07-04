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

  context "when danger-gitlab is not installed" do
    it "gracefully handles missing gitlab gem without raising LoadError" do
      # danger is already required in spec_helper.rb so we have to launch a new process.
      script = <<~RUBY
        # Emulate the environment that does not have gitlab gem.
        module Kernel
          alias original_require require

          def require(name)
            raise LoadError, "cannot load such file -- gitlab" if name == "gitlab"

            original_require(name)
          end
        end

        require "danger"

        Danger::Runner.run([])
      RUBY
      expect { system(RbConfig.ruby, "-e", script) }.not_to output(/LoadError/).to_stderr_from_any_process
    end
  end
end
