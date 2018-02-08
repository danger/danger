RSpec.describe Danger::Violation, host: :github do
  describe "#to_s" do
    it "formats a message" do
      expect(violation_factory("hello!").to_s).to eq("Violation hello! { sticky: false }")
    end

    it "formats a sticky message" do
      expect(violation_factory("hello!", sticky: true).to_s).to eq("Violation hello! { sticky: true }")
    end

    it "formats a message with file and line" do
      expect(violation_factory("hello!", file: "foo.rb", line: 2).to_s).to eq("Violation hello! { sticky: false, file: foo.rb, line: 2 }")
    end
  end
end
