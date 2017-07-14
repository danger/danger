require "spec_helper"
require "danger/ci_source/local_git_repo"
require "ostruct"

RSpec.describe Danger::LocalGitRepo do
  def run_in_repo(merge_pr: true, squash_and_merge_pr: false)
    Dir.mktmpdir do |dir|
      Dir.chdir dir do
        `git init`
        `git remote add origin https://github.com/danger/danger.git`
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

    describe "repo_logs" do
      let(:git_sha_regex) { /\b[0-9a-f]{5,40}\b/ }

      it "returns the git logs correctly" do
        run_in_repo do
          result = source(valid_env)
          expect(result.run_git("log --oneline -1000000".freeze).split("\n")).to match_array [
            /#{git_sha_regex} Merge pull request #1234 from new-branch/,
            /#{git_sha_regex} adding file2/,
            /#{git_sha_regex} adding file1/
          ]
        end
      end

      context "with a non UTF-8 character" do
        let(:invalid_encoded_string) { "testing\xC2 a non UTF-8 string" }

        it "encodes the string correctly" do
          expect { invalid_encoded_string.gsub(//, "") }.to raise_error(ArgumentError)

          run_in_repo do
            File.open("file3", "w") {}
            `git add .`
            `git commit -m "#{invalid_encoded_string}"`

            result = source(valid_env)
            logs = nil
            expect { logs = result.run_git("log --oneline -1000000".freeze) }.to_not raise_error
            expect(logs.split("\n")).to match_array [
              /#{git_sha_regex} testing a non UTF-8 string/,
              /#{git_sha_regex} Merge pull request #1234 from new-branch/,
              /#{git_sha_regex} adding file2/,
              /#{git_sha_regex} adding file1/
            ]
          end
        end
      end
    end

    describe "repo_slug" do
      it "gets the repo slug when it uses https" do
        run_in_repo do
          result = source(valid_env)

          expect(result.repo_slug).to eq("danger/danger")
        end
      end

      it "gets the repo slug when it uses git@" do
        run_in_repo do
          `git remote set-url origin git@github.com:orta/danger.git`

          result = source(valid_env)

          expect(result.repo_slug).to eq("orta/danger")
        end
      end

      it "gets the repo slug when it contains .git" do
        run_in_repo do
          `git remote set-url origin git@github.com:artsy/artsy.github.com.git`

          result = source(valid_env)

          expect(result.repo_slug).to eq("artsy/artsy.github.com")
        end
      end

      it "gets the repo slug when it starts with git://" do
        run_in_repo do
          `git remote set-url origin git://github.com:orta/danger.git`

          result = source(valid_env)

          expect(result.repo_slug).to eq("orta/danger")
        end
      end

      it "does not set a repo_slug if the repo has a non-gh remote" do
        run_in_repo do
          `git remote set-url origin git@git.evilcorp.com:tyrell/danger.git`

          expect { source(valid_env) }.to \
            raise_error(
              RuntimeError,
              /danger cannot find your git remote, please set a remote. And the repository must host on GitHub.com or GitHub Enterprise./
            )
        end
      end

      context "enterprise github repos" do
        it "does set a repo slug if provided with a github enterprise host" do
          run_in_repo do
            `git remote set-url origin git@git.evilcorp.com:tyrell/danger.git`

            result = source(valid_env.merge!("DANGER_GITHUB_HOST" => "git.evilcorp.com"))

            expect(result.repo_slug).to eq("tyrell/danger")
          end
        end

        it "does not set a repo_slug if provided with a github_host that is different from the remote" do
          run_in_repo do
            `git remote set-url origin git@git.evilcorp.com:tyrell/danger.git`

            expect { source(valid_env.merge!("DANGER_GITHUB_HOST" => "git.robot.com")) }.to \
              raise_error(
                RuntimeError,
                /danger cannot find your git remote, please set a remote. And the repository must host on GitHub.com or GitHub Enterprise./
              )
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

    context "forked PR" do
      it "works" do
        spec_root = Dir.pwd
        client = double("Octokit::Client")
        allow(Octokit::Client).to receive(:new) { client }
        allow(client).to receive(:pull_request).with("orta/danger", "42") do
          JSON.parse(
            IO.read("#{spec_root}/spec/fixtures/ci_source/support/fork-pr.json"),
            object_class: OpenStruct
          )
        end

        run_in_repo do
          fork_pr_env = { "LOCAL_GIT_PR_URL" => "https://github.com/orta/danger/pull/42" }
          result = source(valid_env.merge!(fork_pr_env))

          expect(result).to have_attributes(
            repo_slug: "orta/danger",
            pull_request_id: "42",
            base_commit: "base commit sha1",
            head_commit: "head commit sha1"
          )
        end
      end
    end
  end
end
