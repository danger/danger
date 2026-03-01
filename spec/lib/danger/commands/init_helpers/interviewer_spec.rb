require "danger/commands/init_helpers/interviewer"

RSpec.describe Danger::Interviewer do
  let(:cork) { double("cork") }
  let(:interviewer) { Danger::Interviewer.new(cork) }

  describe "#link" do
    before do
      allow(interviewer).to receive(:say)
    end

    it "link URL is decorated" do
      interviewer.link("http://danger.systems/")
      expect(interviewer).to have_received(:say).with(" -> \e[4mhttp://danger.systems/\e[0m\n")
    end
  end
end
