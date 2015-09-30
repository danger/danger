require 'spec_helper'
require 'danger/scm_source/git'

describe Danger::GitRepo do
  it 'gets a diff between head and master' do
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
      g.diff_for_folder(dir)
      expect(g.modified_files.count).to eql(1)
    end
  end

  it 'handles code deletions as expected' do
    Dir.mktmpdir do |dir|
      Dir.chdir dir do
        `git init`
        `touch file`
        `echo "hi\n\nfb\nasdasd" > file`
        `git add .`
        `git commit -m "ok"`
        `git checkout -b new`
        `rm file`
        `touch file`
        `echo "hi" > file`
        `git add .`
        `git commit -m "another"`
      end

      g = Danger::GitRepo.new
      g.diff_for_folder(dir)

      expect(g.lines_of_code).to eql(3)
      expect(g.deletions).to eql(3)
    end
  end

  it 'handles code insertions as expected' do
    Dir.mktmpdir do |dir|
      Dir.chdir dir do
        `git init`
        `touch file`
        `echo "hi\n\nfb\nasdasd" > file`
        `git add .`
        `git commit -m "ok"`
        `git checkout -b new`
        `echo "hi\n\najsdha" > file`
        `git add .`
        `git commit -m "another"`
      end

      g = Danger::GitRepo.new
      g.diff_for_folder(dir)

      expect(g.lines_of_code).to eql(3)
      expect(g.insertions).to eql(1)
    end
  end

  it 'handles added files as expected' do
    Dir.mktmpdir do |dir|
      Dir.chdir dir do
        `git init`
        `touch file`
        `git add .`
        `git commit -m "ok"`
        `git checkout -b new`
        `touch file2`
        `echo "ok" > file2`
        `git add .`
        `git commit -m "another"`
      end

      g = Danger::GitRepo.new
      d = g.diff_for_folder(dir)

      expect(g.added_files).to eql(["file2"])
    end
  end

  it 'handles removed files as expected' do
    Dir.mktmpdir do |dir|
      Dir.chdir dir do
        `git init`
        `touch file`
        `git add .`
        `git commit -m "ok"`
        `git checkout -b new`
        `rm file`
        `git rm file`
        `git commit -m "another"`
      end

      g = Danger::GitRepo.new
      d = g.diff_for_folder(dir)

      expect(g.removed_files).to eql(["file"])
    end
  end
end
