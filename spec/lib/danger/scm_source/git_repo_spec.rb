describe Danger::GitRepo do
  describe "#exec" do
    it "run command with our env set" do
      git_repo = described_class.new
      allow(git_repo).to receive(:default_env) { Hash("LANG" => "zh_TW.UTF-8") }

      result = git_repo.exec("status && echo $LANG")

      expect(result).to match(/zh_TW.UTF-8/)
    end
  end
end
