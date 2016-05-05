# For more info see: https://github.com/schacon/ruby-git

require 'git'

module Danger
  class GitRepoDSL
    def initialize(git)
      @git = git
    end

    def added_files
      Danger::FileList.new(@git.diff.select { |diff| diff.type == "new" }.map(&:path))
    end

    def deleted_files
      Danger::FileList.new(@git.diff.select { |diff| diff.type == "deleted" }.map(&:path))
    end

    def modified_files
      Danger::FileList.new(@git.diff.stats[:files].keys)
    end

    def lines_of_code
      @git.diff.lines
    end

    def deletions
      @git.diff.deletions
    end

    def insertions
      @git.diff.insertions
    end

    def commits
      @git.log.to_a
    end
  end

  class GitRepo
    attr_accessor :dsl, :diff, :log

    def initialize
      self.dsl = GitRepoDSL.new(self)
    end

    def diff_for_folder(folder, from: "master", to: 'HEAD')
      repo = Git.open folder
      self.diff = repo.diff(from, to)
      self.log = repo.log.between(from, to)
    end

    def exec(string)
      `git #{string}`.strip
    end
  end
end
