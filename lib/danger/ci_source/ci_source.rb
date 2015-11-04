module Danger
  module CISource
    # "abstract" CI class
    class CI
      attr_accessor :repo_slug, :pull_request_id

      def self.validates?(_env)
        false
      end

      def initialize(_env)
        raise "Subclass and overwrite initialize"
      end
    end
  end
end

# Import all the other CI classes
Dir[File.expand_path('*.rb', File.dirname(__FILE__))].each do |file|
  next if File.basename(file).downcase == File.basename(__FILE__).downcase
  require file
end
