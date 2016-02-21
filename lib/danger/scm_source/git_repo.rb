# For more info see: https://github.com/schacon/ruby-git

require 'rugged'

module Danger
  class GitRepo
    attr_accessor :diff

    def diff_for_folder(folder, from: "master", to: 'HEAD')
      repo = Rugged::Repository.new folder
      self.diff = repo.diff(from, to)
    end

    def files_modified
      @diff.deltas.select(&:modified?).map(&:new_file).map(&:path)
    end

    def files_removed
      @diff.deltas.select(&:added?).map(&:new_file).map { |hash| hash[:path] }
    end

    def files_added
      @diff.deltas.select(&:added?).map(&:new_file).map { |hash| hash[:path] }
    end

    def lines_of_code
      @diff.patches.map(&:hunks).flatten.map(&:lines).map(&:count).inject(0, :+)
    end

    def deletions
      @diff.patches.map(&:additions).inject(0, :+)
    end

    def insertions
      @diff.patches.map(&:deletions).inject(0, :+)
    end
  end
end
