RSpec.describe Danger::DangerfileGitLabPlugin, host: :gitlab do
  let(:env) { stub_env.merge("CI_MERGE_REQUEST_IID" => 1) }
  let(:dangerfile) { testing_dangerfile(env) }
  let(:plugin) { described_class.new(dangerfile) }
  before do
    stub_merge_request(
      "merge_request_1_response",
      "k0nserv%2Fdanger-test",
      1
    )
  end

  [
    { method: :mr_title, expected_result: "Add a" },
    { method: :mr_body, expected_result: "The descriptions is here\r\n\r\n\u003e Danger: ignore \"Developer specific files shouldn't be changed\"\r\n\r\n\u003e Danger: ignore \"Testing\"" },
    { method: :mr_author, expected_result: "k0nserv" },
    { method: :mr_labels, expected_result: ["test-label"] },
    { method: :branch_for_merge, expected_result: "master" },
    { method: :branch_for_base, expected_result: "master" },
    { method: :branch_for_head, expected_result: "mr-test" }
  ].each do |data|
    method = data[:method]
    expected = data[:expected_result]

    describe "##{method}" do
      it "sets the correct #{method}" do
        with_git_repo(origin: "git@gitlab.com:k0nserv/danger-test.git") do
          dangerfile.env.request_source.fetch_details
          expect(plugin.send(method)).to eq(expected)
        end
      end
    end
  end

  describe "#mr_diff" do
    before do
      stub_merge_request_changes(
        "merge_request_1_changes_response",
        "k0nserv\%2Fdanger-test",
        1
      )
    end

    it "sets the mr_diff" do
      with_git_repo(origin: "git@gitlab.com:k0nserv/danger-test.git") do
        expect(plugin.mr_diff).to include("Danger rocks!")
        expect(plugin.mr_diff).to include("Test message please ignore")
      end
    end
  end

  describe "#mr_changes" do
    before do
      stub_merge_request_changes(
        "merge_request_1_changes_response",
        "k0nserv\%2Fdanger-test",
        1
      )
    end

    it "sets the mr_changes" do
      with_git_repo(origin: "git@gitlab.com:k0nserv/danger-test.git") do
        expect(plugin.mr_changes[0].to_h).to match(hash_including("old_path" => "Dangerfile", "new_path" => "Dangerfile", "a_mode" => "100644", "b_mode" => "100644", "new_file" => false, "renamed_file" => false, "deleted_file" => false, "diff" => an_instance_of(String)))
        expect(plugin.mr_changes[1].to_h).to match(hash_including("old_path" => "a", "new_path" => "a", "a_mode" => "0", "b_mode" => "100644", "new_file" => true, "renamed_file" => false, "deleted_file" => false, "diff" => "--- /dev/null\n+++ b/a\n@@ -0,0 +1 @@\n+Danger rocks!\n"))
        expect(plugin.mr_changes[2].to_h).to match(hash_including("old_path" => "b", "new_path" => "b", "a_mode" => "0", "b_mode" => "100644", "new_file" => true, "renamed_file" => false, "deleted_file" => false, "diff" => "--- /dev/null\n+++ b/b\n@@ -0,0 +1 @@\n+Test message please ignore\n"))
      end
    end
  end

  describe "#mr_commits" do
    before do
      stub_merge_request_commits(
        "merge_request_1_commits_response",
        "k0nserv\%2Fdanger-test",
        1
      )
    end

    it "sets the mr_commits" do
      expect(plugin.mr_commits[0].to_h).to match(hash_including(
        "author_email"=>"john@example.com", "author_name"=>"John Doe", "authored_date" => "2021-10-25T19:44:54.000Z", "committed_date" => "2021-10-26T08:57:40.000Z", "committer_email" => "jane@example.com", "committer_name" => "Jane Doe",
        "created_at" => "2021-10-26T08:57:40.000Z", "id" => "4ec55c9f8b89ca514fcbaf1abe2d76ca928c61e7", "message" => "Update engineering productivity handbook references\n", "parent_ids" => [], "short_id" => "4ec55c9f",
        "title" => "Update engineering productivity handbook references", "trailers" => {}, "web_url" => "https://gitlab.com/k0nserv/danger-test/-/commit/4ec55c9f8b89ca514fcbaf1abe2d76ca928c61e7",))
    end
  end

  describe "#mr_json" do
    it "is set" do
      with_git_repo(origin: "git@gitlab.com:k0nserv/danger-test.git") do
        dangerfile.env.request_source.fetch_details
        expect(plugin.mr_json).not_to be_nil
      end
    end

    it "has the expected keys" do
      with_git_repo(origin: "git@gitlab.com:k0nserv/danger-test.git") do
        dangerfile.env.request_source.fetch_details

        %i(
          id iid project_id title description state created_at
          updated_at target_branch source_branch upvotes downvotes
          author assignee source_project_id target_project_id labels
          work_in_progress milestone merge_when_pipeline_succeeds merge_status
          subscribed user_notes_count approvals_before_merge
          should_remove_source_branch force_remove_source_branch diff_refs
        ).each do |key|
          key_present = plugin.pr_json.key?(key.to_s)
          expect(key_present).to be_truthy, "Expected key #{key} not found"
        end
      end
    end
  end

  describe "#html_link" do
    it "should render a html link to the given file" do
      with_git_repo(origin: "git@gitlab.com:k0nserv/danger-test.git") do
        head_commit = "04e58de1fa97502d7e28c1394d471bb8fb1fc4a8"
        dangerfile.env.request_source.fetch_details

        expect(plugin).to receive(:repository_web_url).
          and_return("https://gitlab.com/k0nserv/danger-test")

        expect(plugin).to receive(:head_commit).
          and_return(head_commit)

        expect(plugin.html_link("CHANGELOG.md")).to eq("<a href='https://gitlab.com/k0nserv/danger-test/blob/#{head_commit}/CHANGELOG.md'>CHANGELOG.md</a>")
      end
    end
  end

  describe "repository_web_url" do
    it "should request the project" do
      with_git_repo(origin: "git@gitlab.com:k0nserv/danger-test.git") do
        expect(plugin).to receive("mr_json").
          and_return({ source_project_id: "15" })

        require "gitlab"
        project = Gitlab::ObjectifiedHash.new({ web_url: "https://gitlab.com/k0nserv/danger-test" })

        expect(plugin.api).to receive("project").
          and_return(project)

        expect(plugin.repository_web_url).to eq("https://gitlab.com/k0nserv/danger-test")
      end
    end
  end
end
