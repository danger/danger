# frozen_string_literal: true

require "danger/output_registry/output_handler_registry"

RSpec.describe Danger::OutputRegistry::Handlers::BitbucketCloud::BitbucketCloudCommentHandler do
  let(:violations) { { warnings: [Danger::Violation.new("careful", false)], errors: [], messages: [] } }
  let(:api) { instance_double(Danger::RequestSources::BitbucketCloudAPI) }

  it "lets a Bitbucket Cloud comment posting error propagate" do
    context = instance_double(Danger::RequestSources::BitbucketCloud)
    allow(context).to receive(:kind_of?).with(Danger::RequestSources::BitbucketCloud).and_return(true)
    allow(context).to receive_messages(delete_old_comments: nil, update_inline_comments_for_kind!: violations[:warnings],
                                       generate_description: "d", generate_comment: "c")
    allow(context).to receive(:instance_variable_get).with(:@api).and_return(api)
    allow(api).to receive(:post_comment).and_raise(RuntimeError, "boom")

    handler = described_class.new(context, violations)

    expect { handler.execute }.to raise_error(RuntimeError, "boom")
  end
end
