describe String do
  describe "#danger_class" do
    it "converts properly" do
      expect("example_class".danger_class).to eq("ExampleClass")
    end
  end

  describe "#danger_underscore" do
    it "converts properly" do
      expect("ExampleClass".danger_underscore).to eq("example_class")
    end
  end
end
