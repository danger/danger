module Danger
  class Files < Plugin
    def protect_files(path: nil, message: nil, fail_build: true)
      raise 'You have to provide a message' if message.to_s.length == 0
      raise 'You have to provide a path' if path.to_s.length == 0

      broken_rule = modified_files.include?(path)

      return unless broken_rule
      fail_build ? fail(message) : warn(message)
    end
  end
end
