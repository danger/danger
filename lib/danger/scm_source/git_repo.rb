# For more info see: https://github.com/schacon/ruby-git

require 'git'

module Danger
  class GitRepo
    attr_accessor :diff, :log

    def diff_for_folder(folder, from: "master", to: 'HEAD')
      repo = Git.open folder
      self.diff = repo.diff(from, to)
      self.log = repo.log.between(from, to)
    end

    def exec(string)
      `git #{string}`.strip
    end

    def origins
      exec "remote show origin -n | grep \"Fetch URL\" | cut -d ':' -f 2-"
    end
  end
end
