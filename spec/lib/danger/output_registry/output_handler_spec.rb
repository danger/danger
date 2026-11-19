# frozen_string_literal: true

require "danger/output_registry/output_handler_registry"

RSpec.describe Danger::OutputRegistry::OutputHandler do
  let(:handler) { described_class.new(double("context"), { warnings: [], errors: [], messages: [] }) }

  it "keeps reports across calls when no shared state was given" do
    violation = Danger::Violation.new("boom", false, "a.rb", 1)

    handler.send(:report_out_of_range_violation, :errors, violation)

    expect(handler.send(:out_of_range_violations)[:errors]).to eq([violation])
  end
end
