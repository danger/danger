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

    it "passes commits count in branch to git log" do
      with_git_repo do |dir|
        @dm = testing_dangerfile

        expect_any_instance_of(Git::Base).to(
          receive(:log).with(1).and_call_original
        )

        @dm.env.scm.diff_for_folder(dir)
      end
    end

    it "assumes the requested folder is the top level git folder by default" do
      with_git_repo do |dir|
        @dm = testing_dangerfile
        expect do
          @dm.env.scm.diff_for_folder(dir + '/subdir')
        end.to raise_error(ArgumentError, /path does not exist/)
      end
    end

    it "looks up the top level git folder when requested" do
      with_git_repo do |dir|
        @dm = testing_dangerfile
        @dm.env.scm.diff_for_folder(dir + '/subdir', lookup_top_level: true)
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

        expect(@dm.git.added_files).to eq(Danger::FileList.new(["file2"]))
        expect(@dm.git.diff_for_file("file2")).not_to be_nil
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
          expect(@dm.git.deleted_files).to eq(Danger::FileList.new(["file"]))
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
          expect(@dm.git.modified_files.compact).to eq(Danger::FileList.new(["file"]))
        end
      end
    end

    it "handles moved files as expected" do
      Dir.mktmpdir do |dir|
        Dir.chdir dir do
          subfolder = "subfolder"

          `git init`
          `git config diff.renames true`
          `git remote add origin git@github.com:danger/danger.git`
          File.open(dir + "/file", "w") { |file| file.write("hi\n\nfb\nasdasd") }
          `git add .`
          `git commit -m "ok"`
          `git checkout -b new --quiet`
          `mkdir "#{subfolder}"`
          `git mv file "#{subfolder}"`
          `git commit -m "another"`

          @dm = testing_dangerfile
          @dm.env.scm.diff_for_folder(dir, from: "master", to: "new")

          # Need to compact here because c50713a changes make AppVeyor fail
          expect(@dm.git.modified_files.compact).to eq(Danger::FileList.new(["file"]))
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

  describe "#renamed_files" do
    it "returns array of hashes with names before and after" do
      Dir.mktmpdir do |dir|
        Dir.chdir dir do
          `git init`
          `git remote add origin git@github.com:danger/danger.git`

          Dir.mkdir(File.join(dir, "first"))
          Dir.mkdir(File.join(dir, "second"))

          File.open(File.join(dir, "first", "a"), "w") { |f| f.write("hi") }
          File.open(File.join(dir, "second", "b"), "w") { |f| f.write("bye") }
          File.open(File.join(dir, "c"), "w") { |f| f.write("Hello") }

          `git add .`
          `git commit -m "Add files"`
          `git checkout -b rename_files --quiet`

          File.delete(File.join(dir, "first", "a"))
          File.delete(File.join(dir, "second", "b"))
          File.delete(File.join(dir, "c"))

          File.open(File.join(dir, "a"), "w") { |f| f.write("hi") }
          File.open(File.join(dir, "first", "b"), "w") { |f| f.write("bye") }
          File.open(File.join(dir, "second", "c"), "w") { |f| f.write("Hello") }

          # Use -A here cause for older versions of git
          # add . don't add removed files to index
          `git add -A .`
          `git commit -m "Rename files"`

          @dm = testing_dangerfile
          @dm.env.scm.diff_for_folder(dir, from: "master", to: "rename_files")

          expectation = [
            { before: "first/a", after: "a" },
            { before: "second/b", after: "first/b" },
            { before: "c", after: "second/c" }
          ]

          expect(@dm.git.renamed_files).to eq(expectation)
        end
      end
    end
  end
end
