require "spec_helper"
require "danger/ci_source/local_git_repo"

RSpec.describe Danger::LocalGitRepo do
  def run_in_repo(merge_pr: true, squash_and_merge_pr: false)
    Dir.mktmpdir do |dir|
      Dir.chdir dir do
        `git init`
        File.open(dir + "/file1", "w") {}
        `git add .`
        `git commit -m "adding file1"`
        `git checkout -b new-branch --quiet`
        File.open(dir + "/file2", "w") {}
        `git add .`
        `git commit -m "adding file2"`
        `git checkout master --quiet`

        if merge_pr
          `git merge new-branch --no-ff -m "Merge pull request #1234 from new-branch"`
        end

        if squash_and_merge_pr
          `git merge new-branch --no-ff -m "New branch (#1234)"`
        end

        yield
      end
    end
  end

  let(:valid_env) do
    {
      "DANGER_USE_LOCAL_GIT" => "true"
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
    it "validates when run by danger local" do
      expect(described_class.validates_as_ci?(valid_env)).to be true
    end

    it "does not validate when run by danger local" do
      expect(described_class.validates_as_ci?(invalid_env)).to be false
    end
  end

  describe "#new" do
    it "sets the pull_request_id" do
      run_in_repo do
        result = source(valid_env.merge!("LOCAL_GIT_PR_ID" => "1234"))

        expect(result.pull_request_id).to eq("1234")
      end
    end

    describe "repo_slug" do
      it "gets the repo slug when it uses https" do
        run_in_repo do
          `git remote add origin https://github.com/danger/danger.git`

          result = source(valid_env)

          expect(result.repo_slug).to eq("danger/danger")
        end
      end

      it "gets the repo slug when it uses git@" do
        run_in_repo do
          `git remote add origin git@github.com:orta/danger.git`

          result = source(valid_env)

          expect(result.repo_slug).to eq("orta/danger")
        end
      end

      it "gets the repo slug when it contains .git" do
        run_in_repo do
          `git remote add origin git@github.com:artsy/artsy.github.com.git`

          result = source(valid_env)

          expect(result.repo_slug).to eq("artsy/artsy.github.com")
        end
      end

      it "gets the repo slug when it starts with git://" do
        run_in_repo do
          `git remote add origin git://github.com:orta/danger.git`

          result = source(valid_env)

          expect(result.repo_slug).to eq("orta/danger")
        end
      end

      it "does not set a repo_slug if the repo has a non-gh remote" do
        run_in_repo do
          `git remote add origin git@git.evilcorp.com:tyrell/danger.git`

          result = source(valid_env)

          expect(result.repo_slug).to be_nil
        end
      end

      context "enterprise github repos" do
        it "does set a repo slug if provided with a github enterprise host" do
          run_in_repo do
            `git remote add origin git@git.evilcorp.com:tyrell/danger.git`

            result = source(valid_env.merge!("DANGER_GITHUB_HOST" => "git.evilcorp.com"))

            expect(result.repo_slug).to eq("tyrell/danger")
          end
        end

        it "does not set a repo_slug if provided with a github_host that is different from the remote" do
          run_in_repo do
            `git remote add origin git@git.evilcorp.com:tyrell/danger.git`

            result = source(valid_env.merge!("DANGER_GITHUB_HOST" => "git.robot.com"))

            expect(result.repo_slug).to be_nil
          end
        end
      end
    end

    context "multiple PRs" do
      def add_another_pr
        # Add a new PR merge commit
        `git checkout -b new-branch2 --quiet`
        File.open("file3", "w") {}
        `git add .`
        `git commit -m "adding file2"`
        `git checkout master --quiet`
        `git merge new-branch2 --no-ff -m "Merge pull request #1235 from new-branch"`
      end

      it "handles finding the resulting PR" do
        run_in_repo(merge_pr: true) do
          add_another_pr

          result = source({ "DANGER_USE_LOCAL_GIT" => "true", "LOCAL_GIT_PR_ID" => "1234" })

          expect(result.pull_request_id).to eq("1234")
        end
      end
    end

    context "no incorrect PR id" do
      it "raise an exception" do
        run_in_repo do
          expect do
            source(valid_env.merge!("LOCAL_GIT_PR_ID" => "1238"))
          end.to raise_error(
            RuntimeError,
            "Could not find the Pull Request (1238) inside the git history for this repo."
          )
        end
      end
    end

    context "no PRs" do
      it "raise an exception" do
        run_in_repo(merge_pr: false) do
          expect do
            source(valid_env)
          end.to raise_error(
            RuntimeError,
            "No recent Pull Requests found for this repo, danger requires at least one Pull Request for the local mode."
          )
        end
      end
    end

    context "squash and merge PR" do
      it "works" do
        run_in_repo(merge_pr: false, squash_and_merge_pr: true) do
          result = source(valid_env)

          expect(result.pull_request_id).to eq "1234"
        end
      end
    end
  end
end
