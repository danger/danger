# For more info see: https://github.com/schacon/ruby-git

require 'git'

module Danger
  class GitRepoDSL
    def initialize(git)
      @git = git
    end

    # @!group Git Files
    # Paths for files that were added during the diff
    # @return [FileList] an [Array] subclass
    #
    def added_files
      Danger::FileList.new(@git.diff.select { |diff| diff.type == "new" }.map(&:path))
    end

    # @!group Git Files
    # Paths for files that were removed during the diff
    # @return [FileList] an [Array] subclass
    #
    def deleted_files
      Danger::FileList.new(@git.diff.select { |diff| diff.type == "deleted" }.map(&:path))
    end

    # @!group Git Files
    # Paths for files that changed during the diff
    # @return [FileList] an [Array] subclass
    #
    def modified_files
      Danger::FileList.new(@git.diff.stats[:files].keys)
    end

    # @!group Git Metadata
    # The overall lines of code added/removed in the diff
    # @return Int
    #
    def lines_of_code
      @git.diff.lines
    end

    # @!group Git Metadata
    # The overall lines of code removed in the diff
    # @return Int
    #
    def deletions
      @git.diff.deletions
    end

    # @!group Git Metadata
    # The overall lines of code added in the diff
    # @return Int
    #
    def insertions
      @git.diff.insertions
    end

    # @!group Git Metadata
    # The log of commits inside the diff
    # @return [Git::Log] from the gem `git`
    #
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
