# frozen_string_literal: true

require "danger/output_registry/output_handler_registry"

RSpec.describe Danger::OutputRegistry::Handlers::GitHub::GitHubCheckHandler do
  let(:ci_source) { double("ci_source", repo_slug: "owner/repo") }
  let(:client) { double("client") }
  let(:context) { instance_double(Danger::RequestSources::GitHub, ci_source: ci_source, client: client, pr_json: { "head" => { "sha" => "abc" } }) }
  let(:check_run) { double("check_run", id: 42) }

  before do
    allow(context).to receive(:kind_of?).with(Danger::RequestSources::GitHub).and_return(true)
  end

  def run(warnings)
    described_class.new(context, { warnings: warnings, errors: [], messages: [] }).execute
  end

  it "creates one check run and adds the remaining annotation batches by updating it" do
    warnings = Array.new(120) { |i| Danger::Violation.new("w#{i}", false, "a.rb", i + 1) }
    batch_sizes = []
    updates = []
    allow(client).to receive(:create_check_run) { |*_args, **opts| batch_sizes << opts[:output][:annotations].size }.and_return(check_run)
    allow(client).to receive(:update_check_run) do |slug, id, **opts|
      updates << [slug, id, opts[:output]]
      batch_sizes << opts[:output][:annotations].size
    end

    run(warnings)

    expect(client).to have_received(:create_check_run).once
    expect(updates.map { |slug, id, _| [slug, id] }).to eq([["owner/repo", 42]] * 2)
    expect(updates.map { |_, _, output| output[:title] }).to all(eq(Danger::OutputRegistry::Handlers::GitHub::GitHubConfig::CHECK_RUN_TITLE))
    expect(updates.map { |_, _, output| output[:annotations].first[:start_line] }).to eq([51, 101])
    expect(batch_sizes).to eq([50, 50, 20])
  end

  it "still creates the check run when there are no inline annotations" do
    expect(client).to receive(:create_check_run).once.and_return(check_run)
    expect(client).not_to receive(:update_check_run)

    run([Danger::Violation.new("general", false)])
  end
end
