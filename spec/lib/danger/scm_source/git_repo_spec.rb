require "danger/scm_source/git_repo"

RSpec.describe Danger::GitRepo, host: :github do
  describe "#exec" do
    it "run command with our env set" do
      git_repo = described_class.new
      allow(git_repo).to receive(:default_env) { Hash("LANG" => "zh_TW.UTF-8") }
      command = Gem.win_platform? ? "status && set LANG" : "status && echo $LANG"

      result = git_repo.exec(command)

      expect(result).to match(/zh_TW.UTF-8/)
    end
  end

  describe "#diff_for_folder" do
    it "fetches if cannot find commits, raises if still can't find after fetched" do
      with_git_repo do |dir|
        @dm = testing_dangerfile

        allow(@dm.env.scm).to receive(:exec).and_return("")
        # This is the thing we care about
        allow(@dm.env.scm).to receive(:exec).with("fetch")

        expect do
          @dm.env.scm.diff_for_folder(dir, from: "master", to: "new")
        end.to raise_error(RuntimeError, /doesn't exist/)
      end
    end
  end

  describe "Return Types" do
    it "#modified_files returns a FileList object" do
      with_git_repo do |dir|
        @dm = testing_dangerfile
        @dm.env.scm.diff_for_folder(dir, from: "master", to: "new")

        expect(@dm.git.modified_files.class).to eq(Danger::FileList)
      end
    end

    it "#added_files returns a FileList object" do
      with_git_repo do |dir|
        @dm = testing_dangerfile
        @dm.env.scm.diff_for_folder(dir, from: "master", to: "new")

        expect(@dm.git.added_files.class).to eq(Danger::FileList)
      end
    end

    it "#deleted_files returns a FileList object" do
      with_git_repo do |dir|
        @dm = testing_dangerfile
        @dm.env.scm.diff_for_folder(dir, from: "master", to: "new")

        expect(@dm.git.deleted_files.class).to eq(Danger::FileList)
      end
    end
  end

  describe "with files" do
    it "handles adding a new file to a git repo" do
      with_git_repo do |dir|
        @dm = testing_dangerfile
        @dm.env.scm.diff_for_folder(dir, from: "master", to: "new")

        expect(@dm.git.added_files).to eq(["file2"])
      end
    end

    it "handles file deletions as expected" do
      Dir.mktmpdir do |dir|
        Dir.chdir dir do
          `git init`
          `git remote add origin git@github.com:danger/danger.git`
          File.open(dir + "/file", "w") { |file| file.write("hi\n\nfb\nasdasd") }
          `git add .`
          `git commit -m "ok"`
          `git checkout -b new --quiet`
          File.delete(dir + "/file")
          `git add . --all`
          `git commit -m "another"`

          @dm = testing_dangerfile
          @dm.env.scm.diff_for_folder(dir, from: "master", to: "new")
          expect(@dm.git.deleted_files).to eq(["file"])
        end
      end
    end

    it "handles modified as expected" do
      Dir.mktmpdir do |dir|
        Dir.chdir dir do
          `git init`
          `git remote add origin git@github.com:danger/danger.git`
          File.open(dir + "/file", "w") { |file| file.write("hi\n\nfb\nasdasd") }
          `git add .`
          `git commit -m "ok"`
          `git checkout -b new --quiet`
          File.open(dir + "/file", "a") { |file| file.write("ok\nmorestuff") }
          `git add .`
          `git commit -m "another"`

          @dm = testing_dangerfile
          @dm.env.scm.diff_for_folder(dir, from: "master", to: "new")

          # Need to compact here because c50713a changes make AppVeyor fail
          expect(@dm.git.modified_files.compact).to eq(["file"])
        end
      end
    end

    it "handles moved files as expected" do
      Dir.mktmpdir do |dir|
        Dir.chdir dir do
          `git init`
          `git config diff.renames true`
          `git remote add origin git@github.com:danger/danger.git`
          File.open(dir + "/file", "w") { |file| file.write("hi\n\nfb\nasdasd") }
          `git add .`
          `git commit -m "ok"`
          `git checkout -b new --quiet`
          `mkdir 'subfolder with => weird name'`
          `git mv file 'subfolder with => weird name'`
          `git commit -m "another"`

          @dm = testing_dangerfile
          @dm.env.scm.diff_for_folder(dir, from: "master", to: "new")

          # Need to compact here because c50713a changes make AppVeyor fail
          expect(@dm.git.modified_files.compact).to eq(["file"])
          expect(@dm.git.diff_for_file("file")).not_to be_nil
        end
      end
    end
  end

  describe "lines of code" do
    it "handles code insertions as expected" do
      Dir.mktmpdir do |dir|
        Dir.chdir dir do
          `git init`
          `git remote add origin git@github.com:danger/danger.git`
          File.open(dir + "/file", "w") { |file| file.write("hi\n\nfb\nasdasd") }
          `git add .`
          `git commit -m "ok"`

          `git checkout -b new --quiet`
          File.open(dir + "/file", "a") { |file| file.write("hi\n\najsdha") }
          `git add .`
          `git commit -m "another"`

          @dm = testing_dangerfile
          @dm.env.scm.diff_for_folder(dir, from: "master", to: "new")

          expect(@dm.git.insertions).to eq(3)
        end
      end
    end

    it "handles code deletions as expected" do
      Dir.mktmpdir do |dir|
        Dir.chdir dir do
          `git init`
          `git remote add origin git@github.com:danger/danger.git`
          File.open(dir + "/file", "w") { |file| file.write("1\n2\n3\n4\n5\n") }
          `git add .`
          `git commit -m "ok"`

          `git checkout -b new --quiet`
          File.open(dir + "/file", "w") { |file| file.write("1\n2\n3\n5\n") }
          `git add .`
          `git commit -m "another"`

          @dm = testing_dangerfile
          @dm.env.scm.diff_for_folder(dir, from: "master", to: "new")

          expect(@dm.git.deletions).to eq(1)
        end
      end
    end

    describe "#commits" do
      it "returns the commits" do
        with_git_repo do |dir|
          @dm = testing_dangerfile
          @dm.env.scm.diff_for_folder(dir, from: "master", to: "new")

          messages = @dm.git.commits.map(&:message)
          expect(messages).to eq(["another"])
        end
      end
    end
  end
end
