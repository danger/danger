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
        head_commit = "04e58de1fa97502d7e28c1394d471bb8fb1fc4a8";
        dangerfile.env.request_source.fetch_details

        expect(plugin).to receive(:head_commit).
          and_return(head_commit)

        expect(plugin.html_link("CHANGELOG.md")).to eq("<a href='https://gitlab.com/k0nserv/danger-test/blob/#{head_commit}/CHANGELOG.md'>CHANGELOG.md</a>")
      end
    end
  end
end
