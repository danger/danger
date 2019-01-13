require "danger/ci_source/support/find_repo_info_from_url"

RSpec.describe Danger::FindRepoInfoFromURL do
  describe "#call" do
    context "no match" do
      it "returns nil" do
        result = described_class.new("https://danger.systems").call

        expect(result).to be nil
      end
    end
  end

  context "GitHub" do
    it "https works" do
      result = described_class.new("https://github.com/torvalds/linux/pull/42").call

      expect(result).to have_attributes(
        slug: "torvalds/linux",
        id: "42"
      )
    end

    it "http with www works" do
      result = described_class.new("http://www.github.com/torvalds/linux/pull/42").call

      expect(result).to have_attributes(
        slug: "torvalds/linux",
        id: "42"
      )
    end
  end

  context "GitLab" do
    it "works with trailing slash" do
      result = described_class.new("https://gitlab.com/gitlab-org/gitlab-ce/merge_requests/42/").call

      expect(result).to have_attributes(
        slug: "gitlab-org/gitlab-ce",
        id: "42"
      )
    end

    it "works with two trailing slashes" do
      result = described_class.new("https://gitlab.com/gitlab-org/gitlab-group/gitlab-ce/merge_requests/42/").call

      expect(result).to have_attributes(
        slug: "gitlab-org/gitlab-group/gitlab-ce",
        id: "42"
      )
    end
  end

  context "Bitbucket" do
    context "bitbucket.org" do
      it "works with regular url" do
        result = described_class.new("https://bitbucket.org/ged/ruby-pg/pull-requests/42").call

        expect(result).to have_attributes(
          slug: "ged/ruby-pg",
          id: "42"
        )
      end

      it "works with another url" do
        result = described_class.new("https://bitbucket.org/some-org/awesomerepo/pull-requests/1324").call

        expect(result).to have_attributes(
          slug: "some-org/awesomerepo",
          id: "1324"
        )
      end

      it "works with trailing slash" do
        result = described_class.new("https://bitbucket.org/some-org/awesomerepo/pull-requests/1324/").call

        expect(result).to have_attributes(
          slug: "some-org/awesomerepo",
          id: "1324"
        )
      end

      it "works with trailing information" do
        result = described_class.new("https://bitbucket.org/some-org/awesomerepo/pull-requests/1324/update-compile-targetsdk-to-28/diff").call

        expect(result).to have_attributes(
          slug: "some-org/awesomerepo",
          id: "1324"
        )
      end  
    end

    context "bitbucket.com" do
      it "works with http + trailing slash" do
        result = described_class.new("http://www.bitbucket.com/ged/ruby-pg/pull-requests/42/").call

        expect(result).to have_attributes(
          slug: "ged/ruby-pg",
          id: "42"
        )
      end
    end
  end

  context "Bitbucket Server" do
    it "works" do
      result = described_class.new("https://example.com/bitbucket/projects/Test/repos/test/pull-requests/1946").call

      expect(result).to have_attributes(
        slug: "Test/test",
        id: "1946"
      )
    end
    it "works with http + trailing slash" do
      result = described_class.new("http://example.com/bitbucket/projects/Test/repos/test/pull-requests/1946/").call

      expect(result).to have_attributes(
        slug: "Test/test",
        id: "1946"
      )
    end
  end
end
