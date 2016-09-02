describe Danger do
  context "when installed danger is outdated and an error is raised" do
    it "prints an upgrade message" do
      allow(Danger::HomeKeeper).to receive(:is_danger_outdated?) { true }
      message = "exception message"
      path = "path"
      exception = StandardError.new("error message")
      contents = "contents"

      expect {
        raise Danger::DSLError.new(message, path, exception.backtrace, contents)
      }.to raise_error(
        Danger::DSLError,
        /Updating the Danger gem might fix the issue./
      )
    end
  end

  describe ".setup!" do
    it "invokes home keeper methods" do
      expect(Danger::HomeKeeper).to receive(:check_home_permission!)
      expect(Danger::HomeKeeper).to receive(:create_latest_version_file!)

      Danger.setup!
    end
  end
end
