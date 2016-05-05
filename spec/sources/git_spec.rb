require 'danger/scm_source/git_repo'

describe Danger::GitRepo do
  describe "Return Types" do
    before do
      @tmp_dir = Dir.mktmpdir
      Dir.chdir(@tmp_dir) do
        `git init`
        `touch file`
        `git add .`
        `git commit -m "ok"`
        `git checkout -b new`
        `touch file2`
        `git add .`
        `git commit -m "another"`
      end

      @g = Danger::GitRepo.new
      @g.diff_for_folder(@tmp_dir, from: "master", to: "new")
    end

    it "#modified_files returns a FileList object" do
      expect(@g.dsl.modified_files.class).to eql(Danger::FileList)
    end

    it "#added_files returns a FileList object" do
      expect(@g.dsl.added_files.class).to eql(Danger::FileList)
    end

    it "#deleted_files returns a FileList object" do
      expect(@g.dsl.deleted_files.class).to eql(Danger::FileList)
    end
  end

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

        expect(g.dsl.added_files).to eql(["file2"])
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

        expect(g.dsl.deleted_files).to eql(["file"])
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

        expect(g.dsl.modified_files).to eql(["file"])
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

        expect(g.dsl.insertions).to eql(3)
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

        expect(g.dsl.deletions).to eql(1)
      end
    end

    describe '#commits' do
      it "returns the commits" do
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

          messages = g.dsl.commits.map(&:message)
          expect(messages).to eq(['another'])
        end
      end
    end
  end
end
