require "danger/commands/init"

RSpec.describe Danger::Init do
  describe "#current_repo_slug" do
    let(:command) { Danger::Init.new CLAide::ARGV.new([]) }

    context "with git url" do
      it "returns correct results" do
        url = "git@github.com:author/repo.git"

        allow_any_instance_of(Danger::GitRepo).to receive(:origins).and_return(url)

        expect(command.current_repo_slug).to eq "author/repo"
      end
    end

    context "with github pages url" do
      it "returns correct results" do
        url = "https://github.com/author/repo.github.io.git"

        allow_any_instance_of(Danger::GitRepo).to receive(:origins).and_return(url)

        expect(command.current_repo_slug).to eq "author/repo.github.io"
      end
    end

    context "with other url" do
      it "returns [Your/Repo]" do
        url = "http://example.com"

        allow_any_instance_of(Danger::GitRepo).to receive(:origins).and_return(url)

        expect(command.current_repo_slug).to eq "[Your/Repo]"
      end
    end
  end
end
