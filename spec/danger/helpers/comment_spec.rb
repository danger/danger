require "danger/helpers/comment"

RSpec.describe Danger::Comment do
  describe ".from_github" do
    it "initializes with GitHub comment data structure" do
      github_comment = { "id" => 42, "body" => "github comment" }

      result = described_class.from_github(github_comment)

      expect(result).to have_attributes(id: 42, body: "github comment")
    end
  end

  describe ".from_gitlab" do
    it "initializes with Gitlab comment data structure" do
      GitlabComment = Struct.new(:id, :body)
      gitlab_comment = GitlabComment.new(42, "gitlab comment")

      result = described_class.from_gitlab(gitlab_comment)

      expect(result).to have_attributes(id: 42, body: "gitlab comment")
    end
  end

  describe "#generated_by_danger?" do
    it "returns true when body contains generated_by_{identifier}" do
      comment = described_class.new(42, '"generated_by_orta"')

      expect(comment.generated_by_danger?("orta")).to be true
    end

    it "returns false when body NOT contains generated_by_{identifier}" do
      comment = described_class.new(42, '"generated_by_orta"')

      expect(comment.generated_by_danger?("artsy")).to be false
    end

    it "returns false when identifier is a substring of actual identifier" do
      comment = described_class.new(42, '"generated_by_danger2"')

      expect(comment.generated_by_danger?("danger")).to be false
    end
  end
end
