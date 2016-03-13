require 'danger/scm_source/git_repo'

describe Danger::GitRepo do
  describe "with files" do
    it 'handles adding a new file to a git repo' do
      Dir.mktmpdir do |dir|
        Dir.chdir dir do
          `git init`
          `touch file`
          `git add .`
          `git commit -m "ok"`

          `git checkout -b new`
          `touch file2`
          `git add .`
          `git commit -m "another"`
        end

        g = Danger::GitRepo.new
        g.diff_for_folder(dir, from: "master", to: "new")

        expect(g.added_files).to eql(["file2"])
      end
    end

    it 'handles file deletions as expected' do
      Dir.mktmpdir do |dir|
        Dir.chdir dir do
          `git init`
          `touch file`
          `echo "hi\n\nfb\nasdasd" > file`
          `git add .`
          `git commit -m "ok"`

          `git checkout -b new`
          `rm file`
          `git add . --all`
          `git commit -m "another"`
        end

        g = Danger::GitRepo.new
        g.diff_for_folder(dir, from: "master", to: "new")

        expect(g.deleted_files).to eql(["file"])
      end
    end

    it 'handles modified as expected' do
      Dir.mktmpdir do |dir|
        Dir.chdir dir do
          `git init`
          `touch file`
          `echo "hi\n\nfb\nasdasd" > file`
          `git add .`
          `git commit -m "ok"`

          `git checkout -b new`
          `echo "ok\nmorestuff" >> file`
          `git add .`
          `git commit -m "another"`
        end

        g = Danger::GitRepo.new
        g.diff_for_folder(dir, from: "master", to: "new")

        expect(g.modified_files).to eql(["file"])
      end
    end
  end

  describe "lines of code" do
    it 'handles code insertions as expected' do
      Dir.mktmpdir do |dir|
        Dir.chdir dir do
          `git init`
          `touch file`
          `echo "hi\n\nfb\nasdasd" > file`
          `git add .`
          `git commit -m "ok"`

          `git checkout -b new`
          `echo "hi\n\najsdha" >> file`
          `git add .`
          `git commit -m "another"`
        end

        g = Danger::GitRepo.new
        g.diff_for_folder(dir, from: "master", to: "new")

        expect(g.insertions).to eql(3)
      end
    end

    it 'handles code deletions as expected' do
      Dir.mktmpdir do |dir|
        Dir.chdir dir do
          `git init`
          `touch file`
          `echo "1\n2\n3\n4\n5\n" > file`
          `git add .`
          `git commit -m "ok"`

          `git checkout -b new`
          `echo "1\n2\n3\n5\n" > file`
          `git add .`
          `git commit -m "another"`
        end

        g = Danger::GitRepo.new
        g.diff_for_folder(dir, from: "master", to: "new")

        expect(g.deletions).to eql(1)
      end
    end
  end
end
