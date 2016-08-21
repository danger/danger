require "danger/scm_source/git_repo"

describe Danger::GitRepo, host: :github do
  describe "Return Types" do
    before do
      @tmp_dir = Dir.mktmpdir
      Dir.chdir(@tmp_dir) do
        `git init`
        File.open(@tmp_dir + "/file", "w") {}
        `git add .`
        `git commit -m "ok"`
        `git checkout -b new`
        File.open(@tmp_dir + "/file2", "w") {}
        `git add .`
        `git commit -m "another"`
      end

      @dm = testing_dangerfile
      @dm.env.scm.diff_for_folder(@tmp_dir, from: "master", to: "new")
    end

    it "#modified_files returns a FileList object" do
      expect(@dm.git.modified_files.class).to eql(Danger::FileList)
    end

    it "#added_files returns a FileList object" do
      expect(@dm.git.added_files.class).to eql(Danger::FileList)
    end

    it "#deleted_files returns a FileList object" do
      expect(@dm.git.deleted_files.class).to eql(Danger::FileList)
    end
  end

  describe "with files" do
    it "handles adding a new file to a git repo" do
      Dir.mktmpdir do |dir|
        Dir.chdir dir do
          `git init`
          File.open(dir + "/file1", "w") {}
          `git add .`
          `git commit -m "ok"`

          `git checkout -b new`
          File.open(dir + "/file2", "w") {}
          `git add .`
          `git commit -m "another"`
        end

        @dm = testing_dangerfile
        @dm.env.scm.diff_for_folder(dir, from: "master", to: "new")

        expect(@dm.git.added_files).to eql(["file2"])
      end
    end

    it "handles file deletions as expected" do
      Dir.mktmpdir do |dir|
        Dir.chdir dir do
          `git init`
          File.open(dir + "/file", "w") { |file| file.write("hi\n\nfb\nasdasd") }
          `git add .`
          `git commit -m "ok"`

          `git checkout -b new`
          File.delete(dir + "/file")
          `git add . --all`
          `git commit -m "another"`
        end

        @dm = testing_dangerfile
        @dm.env.scm.diff_for_folder(dir, from: "master", to: "new")

        expect(@dm.git.deleted_files).to eql(["file"])
      end
    end

    it "handles modified as expected" do
      Dir.mktmpdir do |dir|
        Dir.chdir dir do
          `git init`
          File.open(dir + "/file", "w") { |file| file.write("hi\n\nfb\nasdasd") }
          `git add .`
          `git commit -m "ok"`

          `git checkout -b new`
          File.open(dir + "/file", "a") { |file| file.write("ok\nmorestuff") }
          `git add .`
          `git commit -m "another"`
        end

        @dm = testing_dangerfile
        @dm.env.scm.diff_for_folder(dir, from: "master", to: "new")

        expect(@dm.git.modified_files).to eql(["file"])
      end
    end
  end

  describe "lines of code" do
    it "handles code insertions as expected" do
      Dir.mktmpdir do |dir|
        Dir.chdir dir do
          `git init`
          File.open(dir + "/file", "w") { |file| file.write("hi\n\nfb\nasdasd") }
          `git add .`
          `git commit -m "ok"`

          `git checkout -b new`
          File.open(dir + "/file", "a") { |file| file.write("hi\n\najsdha") }
          `git add .`
          `git commit -m "another"`
        end

        @dm = testing_dangerfile
        @dm.env.scm.diff_for_folder(dir, from: "master", to: "new")

        expect(@dm.git.insertions).to eql(3)
      end
    end

    it "handles code deletions as expected" do
      Dir.mktmpdir do |dir|
        Dir.chdir dir do
          `git init`
          File.open(dir + "/file", "w") { |file| file.write("1\n2\n3\n4\n5\n") }
          `git add .`
          `git commit -m "ok"`

          `git checkout -b new`
          File.open(dir + "/file", "w") { |file| file.write("1\n2\n3\n5\n") }
          `git add .`
          `git commit -m "another"`
        end

        @dm = testing_dangerfile
        @dm.env.scm.diff_for_folder(dir, from: "master", to: "new")

        expect(@dm.git.deletions).to eql(1)
      end
    end

    describe "#commits" do
      it "returns the commits" do
        Dir.mktmpdir do |dir|
          Dir.chdir dir do
            `git init`
            File.open(dir + "/file", "w") { |file| file.write("hi\n\nfb\nasdasd") }
            `git add .`
            `git commit -m "ok"`

            `git checkout -b new`
            File.open(dir + "/file", "a") { |file| file.write("hi\n\najsdha") }
            `git add .`
            `git commit -m "another"`
          end

          @dm = testing_dangerfile
          @dm.env.scm.diff_for_folder(dir, from: "master", to: "new")

          messages = @dm.git.commits.map(&:message)
          expect(messages).to eq(["another"])
        end
      end
    end
  end
end
