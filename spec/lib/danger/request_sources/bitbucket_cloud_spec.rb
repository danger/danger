# coding: utf-8

require "danger/request_sources/bitbucket_cloud"
require "danger/helpers/message_groups_array_helper"
require "danger/danger_core/message_group"
require "danger/danger_core/messages/violation"

RSpec.describe Danger::RequestSources::BitbucketCloud, host: :bitbucket_cloud do
  let(:env) { stub_env }
  let(:bs) { Danger::RequestSources::BitbucketCloud.new(stub_ci, env) }

  describe "#new" do
    it "should not raise uninitialized constant error" do
      expect { described_class.new(stub_ci, env) }.not_to raise_error
    end
  end

  describe "#validates_as_api_source" do
    subject { bs.validates_as_api_source? }

    context "when DANGER_BITBUKETCLOUD_USERNAME, _UUID, and _PASSWORD are set" do
      it { is_expected.to be_truthy }
    end

    context "when DANGER_BITBUCKETCLOUD_USERNAME is unset" do
      let(:env) { stub_env.reject { |k, _| k == "DANGER_BITBUCKETCLOUD_USERNAME" } }
      it { is_expected.to be_falsey }
    end

    context "when DANGER_BITBUCKETCLOUD_USERNAME is empty" do
      let(:env) { stub_env.merge("DANGER_BITBUCKETCLOUD_USERNAME" => "") }
      it { is_expected.to be_falsey }
    end

    context "when DANGER_BITBUCKETCLOUD_UUID is unset" do
      let(:env) { stub_env.reject { |k, _| k == "DANGER_BITBUCKETCLOUD_UUID" } }
      it { is_expected.to be_falsey }
    end

    context "when DANGER_BITBUCKETCLOUD_UUID is empty" do
      let(:env) { stub_env.merge("DANGER_BITBUCKETCLOUD_UUID" => "") }
      it { is_expected.to be_falsey }
    end

    context "when DANGER_BITBUCKETCLOUD_PASSWORD is unset" do
      let(:env) { stub_env.reject { |k, _| k == "DANGER_BITBUCKETCLOUD_PASSWORD" } }

      it { is_expected.to be_falsey }
    end

    context "when DANGER_BITBUCKETCLOUD_PASSWORD is empty" do
      let(:env) { stub_env.merge("DANGER_BITBUCKETCLOUD_PASSWORD" => "") }
      it { is_expected.to be_falsey }
    end
  end

  describe "#pr_json" do
    before do
      stub_pull_request
      bs.fetch_details
    end

    it "has a non empty pr_json after `fetch_details`" do
      expect(bs.pr_json).to be_truthy
    end

    describe "#pr_json[:id]" do
      it "has fetched the same pull request id as ci_sources's `pull_request_id`" do
        expect(bs.pr_json[:id]).to eq(2080)
      end
    end

    describe "#pr_json[:title]" do
      it "has fetched the pull requests title" do
        expect(bs.pr_json[:title]).to eq("This is a danger test for bitbucket cloud")
      end
    end
  end

  describe "#update_pr_by_line!" do
    subject do
      bs.update_pr_by_line!(message_groups: message_groups,
                            danger_id: danger_id,
                            new_comment: new_comment,
                            remove_previous_comments: remove_previous_comments)
    end
    let(:new_comment) { false }
    let(:remove_previous_comments) { false }
    let(:message_groups) { [] }
    let(:danger_id) { Base64.encode64(Random.new.bytes(10)) }
    before { message_groups.extend(Danger::Helpers::MessageGroupsArrayHelper) }
    before { allow(bs).to receive(:delete_old_comments) }
    let(:uri) { "https://api.bitbucket.org/2.0/repositories/ios/fancyapp/pullrequests/2080/comments" }

    before do
      stub_request(:post, uri)
        .to_return(:status => 200, :body => "", :headers => {})
    end

    context "with no message groups" do
      it "uploads the summary comment" do
        subject
        expect(a_request(:post, uri)
               .with(body: { content: { raw: /All green/ } })).to have_been_made
      end
    end

    context "with a message group with some message" do
      let(:message_groups) { [Danger::MessageGroup.new(file: file, line: line)] }
      before do
        message_groups.first << Danger::Violation.new("This is bad!",
                                                      false,
                                                      file,
                                                      line,
                                                      type: type)
      end
      let(:type) { :error }

      context "that is an error" do
        let(:type) { :error }

        context "that doesn't relate to a particular line" do
          let(:file) { nil }
          let(:line) { nil }

          it "uploads the summary comment" do
            subject
            expect(a_request(:post, uri)
              .with(body: { content: { raw: /1 Error.*This is bad!/m } })).to have_been_made
          end
        end
      end

      context "that relates to a particular line" do
        let(:file) { "bad_file.rb" }
        let(:line) { 1 }

        context "when type is error" do
          let(:type) { :error }

          it "summary says one error" do
            subject
            expect(a_request(:post, uri)
              .with(body: { content: { raw: /1 Error/ } })).to have_been_made
          end

          it "makes a request for the error" do
            subject
            expect(
              a_request(:post, uri)
              .with(body: {
                      content: {
                        raw: /This is bad!/
                      },
                      inline: {
                        path: file,
                        to: line
                      }
                   })
            ).to have_been_made
          end
        end
        context "when type is warning" do
          let(:type) { :warning }

          it "summary says one warning" do
            subject
            expect(a_request(:post, uri)
              .with(body: { content: { raw: /1 Warning/ } })).to have_been_made
          end

          it "makes a request for the warning" do
            subject
            expect(
              a_request(:post, uri)
              .with(body: {
                      content: {
                        raw: /This is bad!/
                      },
                      inline: {
                        path: file,
                        to: line
                      }
                   })
            ).to have_been_made
          end
        end
      end
    end
  end
end
