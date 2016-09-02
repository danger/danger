describe Danger do
  describe ".setup!" do
    it "invokes home keeper methods" do
      expect(Danger::HomeKeeper).to receive(:check_home_permission!)
      expect(Danger::HomeKeeper).to receive(:create_latest_version_file!)

      Danger.setup!
    end
  end
end
