RSpec.describe Danger::EmojiMapper do
  subject(:emoji_mapper) { described_class.new(template) }

  shared_examples_for "github" do
    describe "#map" do
      subject { emoji_mapper.map(emoji) }

      context "when emoji is no_entry_sign" do
        let(:emoji) { "no_entry_sign" }

        it { is_expected.to eq "🚫" }
      end

      context "when emoji is warning" do
        let(:emoji) { "warning" }

        it { is_expected.to eq "⚠️" }
      end

      context "when emoji is book" do
        let(:emoji) { "book" }

        it { is_expected.to eq "📖" }
      end

      context "when emoji is white_check_mark" do
        let(:emoji) { "white_check_mark" }

        it { is_expected.to eq "✅" }
      end
    end

    describe "#from_type" do
      subject { emoji_mapper.from_type(type) }

      context "when type is :error" do
        let(:type) { :error }

        it { is_expected.to eq "🚫" }
      end

      context "when type is warning" do
        let(:type) { :warning }

        it { is_expected.to eq "⚠️" }
      end

      context "when type is message" do
        let(:type) { :message }

        it { is_expected.to eq "📖" }
      end
    end
  end

  context "when template is github" do
    let(:template) { "github" }

    include_examples "github"
  end

  context "when template is something weird" do
    let(:template) { "respect_potatoes" }

    it_behaves_like "github"
  end

  context "when template is bitbucket_server" do
    let(:template) { "bitbucket_server" }
    describe "#map" do
      subject { emoji_mapper.map(emoji) }

      context "when emoji is no_entry_sign" do
        let(:emoji) { "no_entry_sign" }

        it { is_expected.to eq ":no_entry_sign:" }
      end

      context "when emoji is warning" do
        let(:emoji) { "warning" }

        it { is_expected.to eq ":warning:" }
      end

      context "when emoji is book" do
        let(:emoji) { "book" }

        it { is_expected.to eq ":book:" }
      end

      context "when emoji is white_check_mark" do
        let(:emoji) { "white_check_mark" }

        it { is_expected.to eq ":white_check_mark:" }
      end
    end

    describe "#from_type" do
      subject { emoji_mapper.from_type(type) }

      context "when type is :error" do
        let(:type) { :error }

        it { is_expected.to eq ":no_entry_sign:" }
      end

      context "when type is warning" do
        let(:type) { :warning }

        it { is_expected.to eq ":warning:" }
      end

      context "when type is message" do
        let(:type) { :message }

        it { is_expected.to eq ":book:" }
      end
    end
  end
end
