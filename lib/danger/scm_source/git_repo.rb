# https://github.com/schacon/ruby-git

require 'git'

module Danger
  class GitRepo
    attr_accessor :diff

    def diff_for_folder(folder, from = "HEAD", to = 'master')
      g = Git.open(folder)
      self.diff = g.diff(to, from)
    end

    def modified_files
      @diff.to_a.map(&:path)
    end

    def removed_files
      @diff.to_a.select { |d| d.type == "deleted" }.map(&:path)
    end

    def added_files
      @diff.to_a.select { |d| d.type == "new" }.map(&:path)
    end

    def lines_of_code
      @diff.lines
    end

    def deletions
      @diff.deletions
    end

    def insertions
      @diff.insertions
    end
  end
end
