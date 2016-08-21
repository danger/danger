describe Danger::DangerfileGitLabPlugin, host: :gitlab do
  let(:dangerfile) { testing_dangerfile }
  let(:plugin) { described_class.new(dangerfile) }
  before do
    stub_merge_request(
      "merge_request_593728_response",
      "k0nserv/danger-test",
      593_728
    )
    stub_merge_request_commits(
      "merge_request_593728_commits_response",
      "k0nserv/danger-test",
      593_728
    )
  end

  [
    { method: :pr_title, expected_result: "Add a" },
    { method: :pr_body, expected_result: "The descriptions is here\r\n\r\n\u003e Danger: ignore \"Developer specific files shouldn't be changed\"\r\n\r\n\u003e Danger: ignore \"Testing\"" },
    { method: :pr_author, expected_result: "k0nserv" },
    { method: :pr_labels, expected_result: ["test-label"] },
    { method: :branch_for_merge, expected_result: "master" }

  ].each do |data|
    method = data[:method]
    expected = data[:expected_result]

    describe "##{method}" do
      it "sets the correct #{method}" do
        with_gitlab_git_repo do
          dangerfile.env.request_source.fetch_details
          expect(plugin.send(method)).to eq(expected)
        end
      end
    end
  end

  describe "#pr_json" do
    it "is set" do
      with_gitlab_git_repo do
        dangerfile.env.request_source.fetch_details
        expect(plugin.pr_json).not_to be_nil
      end
    end

    it "has the expected keys" do
      with_gitlab_git_repo do
        dangerfile.env.request_source.fetch_details
        json = plugin.pr_json

        [
          :id, :iid, :project_id, :title, :description, :state, :created_at,
          :updated_at, :target_branch, :source_branch, :upvotes, :downvotes,
          :author, :assignee, :source_project_id, :target_project_id, :labels,
          :work_in_progress, :milestone, :merge_when_build_succeeds, :merge_status,
          :subscribed, :user_notes_count, :approvals_before_merge,
          :should_remove_source_branch, :force_remove_source_branch
        ].each do |key|
          key_present = plugin.pr_json.key?(key.to_s)
          expect(key_present).to be_truthy, "Expected key #{key} not found"
        end
      end
    end
  end
end
