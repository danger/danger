# frozen_string_literal: true

require "danger/output_registry/output_handler_registry"

RSpec.describe "Bitbucket Server output handlers" do
  let(:violations) { { warnings: [Danger::Violation.new("careful", false)], errors: [], messages: [] } }
  let(:api) { instance_double(Danger::RequestSources::BitbucketServerAPI) }

  it "lets a Bitbucket Server comment posting error propagate" do
    context = instance_double(Danger::RequestSources::BitbucketServer)
    allow(context).to receive(:kind_of?).with(Danger::RequestSources::BitbucketServer).and_return(true)
    allow(context).to receive_messages(delete_old_comments: nil, main_violations_group: violations,
                                       generate_description: "d", generate_comment: "c")
    allow(context).to receive(:instance_variable_get).with(:@api).and_return(api)
    allow(context).to receive(:instance_variable_get).with(:@code_insights).and_return(nil)
    allow(api).to receive(:post_comment).and_raise(RuntimeError, "boom")

    handler = Danger::OutputRegistry::Handlers::BitbucketServer::BitbucketServerCommentHandler.new(context, violations)

    expect { handler.execute }.to raise_error(RuntimeError, "boom")
  end

  it "lets a Code Insights report error propagate" do
    context = instance_double(Danger::RequestSources::BitbucketServer)
    code_insights = instance_double(Danger::RequestSources::CodeInsightsAPI, ready?: true)
    allow(context).to receive(:kind_of?).with(Danger::RequestSources::BitbucketServer).and_return(true)
    allow(context).to receive_messages(inline_violations_group: {}, pr_json: { fromRef: { latestCommit: "abc" } })
    allow(context).to receive(:instance_variable_get).with(:@code_insights).and_return(code_insights)
    allow(code_insights).to receive(:send_report).and_raise(RuntimeError, "boom")

    handler = Danger::OutputRegistry::Handlers::BitbucketServer::BitbucketServerCodeInsightsHandler.new(context, violations)

    expect { handler.execute }.to raise_error(RuntimeError, "boom")
  end
end
