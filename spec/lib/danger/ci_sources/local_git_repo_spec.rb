require "spec_helper"
require "danger/ci_source/local_git_repo"

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

describe Danger::LocalGitRepo do
  let(:valid_env) do
    {
      "DANGER_USE_LOCAL_GIT" => "true",
    }
  end

  let(:invalid_env) do
    {
      "CIRCLE" => "true"
    }
  end

  let(:source) { described_class.new(valid_env) }

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
        expect(source.pull_request_id).to eql("1234")
      end
    end

    describe "repo_slug" do
      it "gets the repo address when it uses git@" do
        run_in_repo do
          `git remote add origin git@github.com:orta/danger.git`
          expect(source.repo_slug).to eql("orta/danger")
        end
      end

      it "gets the repo address when it contains .git" do
        run_in_repo do
          `git remote add origin git@github.com:artsy/artsy.github.com.git`
          expect(source.repo_slug).to eql("artsy/artsy.github.com")
        end
      end

      it "gets the repo address when it starts with git://" do
        run_in_repo do
          `git remote add origin git://github.com:orta/danger.git`
          expect(source.repo_slug).to eql("orta/danger")
        end
      end

      it "does not set a repo_slug if the repo has a non-gh remote" do
        run_in_repo do
          `git remote add origin git@git.evilcorp.com:tyrell/danger.git`
          expect(source.repo_slug).to be_nil
        end
      end

      context "enterprise github repos" do
        it "does set a repo_slug if provided with a github_host" do
          run_in_repo do
            `git remote add origin git@git.evilcorp.com:tyrell/danger.git`
            env = { "DANGER_USE_LOCAL_GIT" => "true", "DANGER_GITHUB_HOST" => "git.evilcorp.com" }
            valid_env["DANGER_GITHUB_HOST"] = "git.evilcorp.com"
            expect(source.repo_slug).to eql("tyrell/danger")
          end
        end

        it "does not set a repo_slug if provided with a github_host that is different from the remote" do
          run_in_repo do
            `git remote add origin git@git.evilcorp.com:tyrell/danger.git`
            valid_env["DANGER_GITHUB_HOST"] = "git.robot.com"
            expect(source.repo_slug).to be_nil
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
          run_in_repo do
            add_another_pr

            env = { "DANGER_USE_LOCAL_GIT" => "true", "LOCAL_GIT_PR_ID" => "1234" }
            t = Danger::LocalGitRepo.new(env)
            expect(t.pull_request_id).to eql("1234")
          end
        end
      end

      context "no incorrect PR id" do
        it "raise an exception" do
          run_in_repo do
            valid_env["LOCAL_GIT_PR_ID"] = "1238"

            expect { source }.to raise_error RuntimeError
          end
        end
      end

      context "no PRs" do
        it "raise an exception" do
          run_in_repo(merge_pr: false) do
            expect { source }.to raise_error RuntimeError
          end
        end
      end

      context "squash and merge PR" do
        it "works" do
          run_in_repo(merge_pr: false, squash_and_merge_pr: true) do
            expect(source.pull_request_id).to eq "1234"
          end
        end
      end
    end
  end
end
