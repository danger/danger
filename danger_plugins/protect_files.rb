module Danger
  class Files < Plugin
    def protect_files(path: nil, message: nil, fail_build: true)
      raise "You have to provide a message" if message.to_s.length == 0
      raise "You have to provide a path" if path.to_s.length == 0
      broken_rule = false

      Dir.glob(path) do |current|
        broken_rule = true if self.env.scm.dsl.modified_files.include?(current)
      end

      return unless broken_rule
      fail_build ? fail(message) : warn(message)
    end
  end
end
