require 'danger/ci_source/ci_source'

describe Danger::CISource::Buildkite do
  before do
    @request_source = Danger::RequestSources::GitHub
    @ci_source = stub_ci
  end

  it "fails if given request source is not supported" do
    allow(@ci_source).to receive(:supported_request_sources).and_return([])
    expect(@ci_source.supports?(@request_source)).to be false
  end

  it "supports a supported request source" do
    allow(@ci_source).to receive(:supported_request_sources).and_return([Danger::RequestSources::GitHub])
    expect(@ci_source.supports?(@request_source)).to be true
  end
end
