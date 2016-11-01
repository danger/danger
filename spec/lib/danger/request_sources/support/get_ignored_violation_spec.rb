RSpec.describe GetIgnoredViolation do
  describe "#call" do
    context "Without specific ignore sentence" do
      it "returns empty array" do
        result = described_class.new("No danger ignore").call

        expect(result).to eq []
      end
    end

    context "With specific ignore sentence" do
      it "returns content in the quotes" do
        sentence = %(Danger: Ignore "This build didn't pass tests")
        result = described_class.new(sentence).call

        expect(result).to eq ["This build didn't pass tests"]
      end
    end

    context "With specific ignore sentence contains escapted quote" do
      it "returns content in the quotes" do
        sentence = %("ignoring this:\r\n>Danger: Ignore \"`TophatModels.v20` changed.\"")
        result = described_class.new(sentence).call

        expect(result).to eq [%(`TophatModels.v20` changed.)]
      end
    end
  end
end
