describe String do
  describe "#danger_class" do
    it "converts properly" do
      expect("example_class".danger_class).to eq("ExampleClass")
    end
  end

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
end
