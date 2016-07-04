require 'danger/plugin_support/plugin'
require 'danger/core_ext/file_list'

module Danger
  # Handles interacting with git inside a Dangerfile. Providing access to files that have changed, and useful statistics. Also provides
  # access to the commits in the form of [Git::Log](https://github.com/schacon/ruby-git/blob/master/lib/git/log.rb) objects.
  #
  # @example Do something to all new and edited markdown files
  #
  #          markdowns = (git.added_files + git.modified_files)
  #          do_something markdowns.select{ |file| file.end_with? "md" }
  #
  # @example Don't allow a file to be deleted
  #
  #          deleted = git.deleted_files.include? "my/favourite.file"
  #          fail "Don't delete my precious" if deleted
  #
  # @example Fail really big diffs
  #
  #          fail "We cannot handle the scale of this PR" if git.lines_of_code > 50_000
  #
  # @example Warn when there are merge commits in the diff
  #
  #          if commits.any? { |c| c.message =~ /^Merge branch 'master'/ }
  #             warn 'Please rebase to get rid of the merge commits in this PR'
  #          end
  #
  #
  # @see  danger/danger
  # @tags core, git

  class DangerfileGitPlugin < Plugin
    def self.instance_name
      'git'
    end

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
      Danger::FileList.new(@git.diff.select { |diff| diff.type == 'new' }.map(&:path))
    end

    # @!group Git Files
    # Paths for files that were removed during the diff
    # @return [FileList] an [Array] subclass
    #
    def deleted_files
      Danger::FileList.new(@git.diff.select { |diff| diff.type == 'deleted' }.map(&:path))
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
