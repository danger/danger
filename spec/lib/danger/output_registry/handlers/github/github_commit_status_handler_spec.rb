# frozen_string_literal: true

require "danger/output_registry/output_handler_registry"

RSpec.describe Danger::OutputRegistry::Handlers::GitHub::GitHubCommitStatusHandler do
  let(:context) { instance_double(Danger::RequestSources::GitHub) }
  let(:warning) { Danger::Violation.new("careful", false) }
  let(:error) { Danger::Violation.new("boom", false) }
  let(:violations) { { warnings: [warning], errors: [error], messages: [] } }

  before do
    allow(context).to receive(:kind_of?).with(Danger::RequestSources::GitHub).and_return(true)
  end

  it "submits the status through the request source" do
    expect(context).to receive(:submit_pull_request_status!)
      .with(warnings: [warning], errors: [error], details_url: "https://example.com/c", danger_id: "my-danger")

    described_class.new(context, violations, danger_id: "my-danger",
                                             shared_state: { comment_url: "https://example.com/c" }).execute
  end

  it "sends no details url when the comment handler has not run" do
    expect(context).to receive(:submit_pull_request_status!)
      .with(warnings: [warning], errors: [error], details_url: nil, danger_id: "danger")

    described_class.new(context, violations, shared_state: {}).execute
  end

  it "does nothing for other request sources" do
    allow(context).to receive(:kind_of?).with(Danger::RequestSources::GitHub).and_return(false)
    expect(context).not_to receive(:submit_pull_request_status!)

    described_class.new(context, violations).execute
  end
end
