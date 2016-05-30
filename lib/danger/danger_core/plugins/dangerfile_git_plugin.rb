require 'danger/plugin_support/plugin'
require 'danger/core_ext/file_list'

module Danger
  class DangerfileGitPlugin < Plugin
    def initialize(dangerfile)
      super(dangerfile)
      raise  unless dangerfile.env.scm.class == Danger::GitRepo

      @git = dangerfile.env.scm
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
end
