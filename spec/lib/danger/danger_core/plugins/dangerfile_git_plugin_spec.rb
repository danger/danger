require "ostruct"

def run_in_repo_with_diff
  Dir.mktmpdir do |dir|
    Dir.chdir dir do
      `git init`
      File.open(dir + "/file1", "w") { |f| f.write "More buritto please." }
      File.open(dir + "/file2", "w") { |f| f.write "Shorts.\nShoes." }
      `git add .`
      `git commit -m "adding file1 & file2"`
      `git tag 1.0.0`
      `git checkout -b new-branch --quiet`
      File.open(dir + "/file2", "w") { |f| f.write "Pants!" }
      File.open(dir + "/file3", "w") { |f| f.write "Jawns.\nYou know, jawns." }
      File.delete(dir + "/file1")
      `git add .`
      `git commit -m "update file2, add file 3, remove file1"`
      g = Git.open(".")
      yield g
    end
  end
end

RSpec.describe Danger::DangerfileGitPlugin, host: :github do
  it "fails init if the dangerfile's request source is not a GitRepo" do
    dm = testing_dangerfile
    dm.env.scm = []
    expect { described_class.new dm }.to raise_error RuntimeError
  end

  describe "dsl" do
    before do
      dm = testing_dangerfile
      @dsl = described_class.new dm
      @repo = dm.env.scm
    end

    it "gets added_files " do
      diff = [OpenStruct.new(type: "new", path: "added")]
      allow(@repo).to receive(:diff).and_return(diff)

      expect(@dsl.added_files).to eq(Danger::FileList.new(["added"]))
    end

    it "gets deleted_files " do
      diff = [OpenStruct.new(type: "deleted", path: "deleted")]
      allow(@repo).to receive(:diff).and_return(diff)

      expect(@dsl.deleted_files).to eq(Danger::FileList.new(["deleted"]))
    end

    it "gets modified_files " do
      diff = [OpenStruct.new(type: "modified", path: "my/path/file_name")]
      allow(@repo).to receive(:diff).and_return(diff)

      expect(@dsl.modified_files).to eq(Danger::FileList.new(["my/path/file_name"]))
    end

    it "gets lines_of_code" do
      diff = OpenStruct.new(lines: 2)
      allow(@repo).to receive(:diff).and_return(diff)

      expect(@dsl.lines_of_code).to eq(2)
    end

    it "gets deletions" do
      diff = OpenStruct.new(deletions: 4)
      allow(@repo).to receive(:diff).and_return(diff)

      expect(@dsl.deletions).to eq(4)
    end

    it "gets insertions" do
      diff = OpenStruct.new(insertions: 6)
      allow(@repo).to receive(:diff).and_return(diff)

      expect(@dsl.insertions).to eq(6)
    end

    it "gets commits" do
      log = ["hi"]
      allow(@repo).to receive(:log).and_return(log)

      expect(@dsl.commits).to eq(log)
    end

    it "gets tags" do
      tag = "1.0.0\n2.0.0"
      allow(@repo).to receive(:tags).and_return(tag)

      expect(@dsl.tags).to all be_a(String)
    end

    describe "getting diff for a specific file" do
      it "returns nil when a specific diff does not exist" do
        run_in_repo_with_diff do |git|
          diff = git.diff("master")
          allow(@repo).to receive(:diff).and_return(diff)
          expect(@dsl.diff_for_file("file_nope_no_way")).to be_nil
        end
      end

      it "gets a specific diff" do
        run_in_repo_with_diff do |git|
          diff = git.diff("master")
          allow(@repo).to receive(:diff).and_return(diff)
          expect(@dsl.diff_for_file("file2")).to_not be_nil
        end
      end
    end

    describe "getting info for a specific file" do
      it "returns nil when specific info does not exist" do
        run_in_repo_with_diff do |git|
          diff = git.diff("master")
          allow(@repo).to receive(:diff).and_return(diff)
          expect(@dsl.info_for_file("file_nope_no_way")).to be_nil
        end
      end

      it "returns file info when it is modified" do
        run_in_repo_with_diff do |git|
          diff = git.diff("master")
          allow(@repo).to receive(:diff).and_return(diff)
          info = @dsl.info_for_file("file2")
          expect(info).to_not be_nil
          expect(info[:insertions]).to equal(1)
          expect(info[:deletions]).to equal(2)
          expect(info[:before]).to eq("Shorts.\nShoes.")
          expect(info[:after]).to eq("Pants!")
        end
      end

      it "returns file info when it is added" do
        run_in_repo_with_diff do |git|
          diff = git.diff("master")
          allow(@repo).to receive(:diff).and_return(diff)
          info = @dsl.info_for_file("file3")
          expect(info).to_not be_nil
          expect(info[:insertions]).to equal(2)
          expect(info[:deletions]).to equal(0)
          expect(info[:before]).to be_nil
          expect(info[:after]).to be_nil
        end
      end

      it "returns file info when it is deleted" do
        run_in_repo_with_diff do |git|
          diff = git.diff("master")
          allow(@repo).to receive(:diff).and_return(diff)
          info = @dsl.info_for_file("file1")
          expect(info).to_not be_nil
          expect(info[:insertions]).to equal(0)
          expect(info[:deletions]).to equal(1)
          expect(info[:before]).to be_nil
          expect(info[:after]).to be_nil
        end
      end
    end

    describe "#renamed_files" do
      it "delegates to scm" do
        renamed_files = [{
          before: "some/path/old",
          after: "some/path/new"
        }]

        allow(@repo).to receive(:renamed_files).and_return(renamed_files)
        expect(@dsl.renamed_files).to eq(renamed_files)
      end
    end

    describe "#diff" do
      it "delegates to scm" do
        allow(@repo).to receive(:diff).and_return(:diff)
        expect(@dsl.diff).to eq(:diff)
      end
    end
  end
end
