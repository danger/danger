require "spec_helper"
require "danger/ci_source/local_only_git_repo"

RSpec.describe Danger::LocalOnlyGitRepo do
  def run_in_repo
    Dir.mktmpdir do |dir|
      Dir.chdir dir do
        `git init`
        `git remote add origin .`
        File.open(dir + "/file1", "w") {}
        `git add .`
        `git commit -m "adding file1"`
        `git fetch`
        `git checkout -b feature_branch`
        File.open(dir + "/file2", "w") {}
        `git add .`
        `git commit -m "adding file2"`

        yield
      end
    end
  end

  let(:valid_env) do
    {
      "DANGER_USE_LOCAL_ONLY_GIT" => "true"
    }
  end

  let(:invalid_env) do
    {
      "CIRCLE" => "true"
    }
  end

  def source(env)
    described_class.new(env)
  end

  describe "validates_as_ci?" do
    context "when run as danger dry_run" do
      it "validates as CI source" do
        expect(described_class.validates_as_ci?(valid_env)).to be true
      end
    end

    it "does not validate as CI source outside danger dry_run" do
      expect(described_class.validates_as_ci?(invalid_env)).to be false
    end
  end

  describe "#new" do
    it "sets base_commit" do
      run_in_repo do
        expect(source(valid_env).base_commit).to eq("origin/master")
      end
    end

    it "sets head_commit" do
      run_in_repo do
        expect(source(valid_env).head_commit).to eq("feature_branch")
      end
    end
  end
end
