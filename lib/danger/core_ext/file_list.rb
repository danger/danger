module Danger
  class FileList < Array
    # Information about pattern: http://ruby-doc.org/core-2.2.0/File.html#method-c-fnmatch
    # e.g. "**/something.*" for any file called something with any extension

    def include?(pattern)
      self.each do |current|
        return true if File.fnmatch(pattern, current)
      end
      return false
    end
  end
end
