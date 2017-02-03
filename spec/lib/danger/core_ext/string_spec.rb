RSpec.describe String do
  describe "#danger_pluralize" do
    examples = [
      { count: 0, string: "0 errors" },
      { count: 1, string: "1 error" },
      { count: 2, string: "2 errors" }
    ]

    examples.each do |example|
      it "returns '#{example[:string]}' when count = #{example[:count]}" do
        expect("error".danger_pluralize(example[:count])).to eq(example[:string])
      end
    end
  end

  describe "#danger_underscore" do
    it "converts properly" do
      expect("ExampleClass".danger_underscore).to eq("example_class")
    end
  end

  describe "#danger_truncate" do
    it "truncates strings exceeding the limit" do
      expect("super long string".danger_truncate(5)).to eq("super...")
    end

    it "does not truncate strings that are on the limit" do
      expect("12345".danger_truncate(5)).to eq("12345")
    end

    it "does not truncate strings that are within the limit" do
      expect("123".danger_truncate(5)).to eq("123")
    end
  end
end
