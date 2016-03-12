# For more info see: https://github.com/schacon/ruby-git

require 'grit'

module Danger
  class GitRepo
    attr_accessor :diff

    def perform_git_operation(string)
      system "git #{string}"
    end

    def diff_for_folder(folder, from: "master", to: 'HEAD')
      repo = Grit::Repo.new folder
      self.diff = repo.diff(from, to)
    end

    def files_added
      @diff.select(&:new_file).map(&:b_path)
    end

    def files_deleted
      @diff.select(&:deleted_file).map(&:a_path)
    end

    def files_modified
      @diff.reject(&:deleted_file).reject(&:new_file).map(&:a_path)
    end

    def lines_of_code
      @diff.map(&:diff).map(&:lines).flatten.count { |l| l.start_with?("+") || l.start_with?("-") }
    end

    def deletions
      @diff.map(&:diff).map(&:lines).flatten.count { |l| l.start_with?("-") }
    end

    def insertions
      @diff.map(&:diff).map(&:lines).flatten.count { |l| l.start_with?("+") }
    end
  end
end
