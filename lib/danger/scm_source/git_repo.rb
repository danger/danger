# For more info see: https://github.com/schacon/ruby-git

require 'rugged'

module Danger
  class GitRepo
    attr_accessor :diff

    def diff_for_folder(folder, from: "master", to: 'HEAD')
      repo = Rugged::Repository.new folder
      self.diff = repo.diff(from, to)
    end

    # Create files_added? methods from rugged's git API
    # https://github.com/libgit2/rugged/blob/master/lib/rugged/diff/delta.rb#L16-L46

    [:added, :deleted, :modified, :renamed, :copied, :ignored, :untracked, :typechange].each do |symbol|
      question_symbol = (symbol.to_s + "?").to_sym
      define_method("files_#{symbol}") do
        @diff.deltas.select(&question_symbol).map(&:new_file).map { |hash| hash[:path] }
      end
    end

    def lines_of_code
      @diff.patches.map(&:hunks).flatten.map(&:lines).map(&:count).inject(0, :+)
    end

    def deletions
      @diff.patches.map(&:deletions).inject(0, :+)
    end

    def insertions
      @diff.patches.map(&:additions).inject(0, :+)
    end
  end
end
