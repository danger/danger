# So much was ripped direct from CocoaPods-Core - thanks!

require 'danger/dangerfile_dsl'
require 'danger/standard_error'

module Danger
  class Dangerfile
    include Danger::Dangerfile::DSL

    # The DSL includes a bunch of read only  attributes + docs
    # we make them readwrite in here
    attr_accessor :files_modified, :files_removed, :files_added, :pr_title, :pr_body, :lines_of_code
    attr_accessor :env, :warnings, :failures

    # @return [Pathname] the path where the Dangerfile was loaded from. It is nil
    #         if the podfile was generated programmatically.
    #
    attr_accessor :defined_in_file

    # @return [String] a string useful to represent the Dangerfile in a message
    #         presented to the user.
    #
    def to_s
      'Dangerfile'
    end

    # Parses the file at a path, optionally takes the content of the file for DI
    #
    def parse(path, contents = nil)
      contents ||= File.open(path, 'r:utf-8', &:read)

      # Work around for Rubinius incomplete encoding in 1.9 mode
      if contents.respond_to?(:encoding) && contents.encoding.name != 'UTF-8'
        contents.encode!('UTF-8')
      end

      if contents.tr!('“”‘’‛', %(""'''))
        # Changes have been made
        puts "Your #{path.basename} has had smart quotes sanitised. " \
                    'To avoid issues in the future, you should not use ' \
                    'TextEdit for editing it. If you are not using TextEdit, ' \
                    'you should turn off smart quotes in your editor of choice.'.red
      end

      self.defined_in_file = path
      instance_eval do
        # rubocop:disable Lint/RescueException
        begin
          # rubocop:disable Eval
          eval(contents, nil, path.to_s)
          # rubocop:enable Eval
        rescue Exception => e
          message = "Invalid `#{path.basename}` file: #{e.message}"
          raise DSLError.new(message, path, e.backtrace, contents)
        end
        # rubocop:enable Lint/RescueException
      end
    end

    def update_from_env
      # SCM Source
      self.files_modified = env.git.files_modified
      self.files_removed = env.git.files_removed
      self.files_added = env.git.files_added
      self.lines_of_code = env.git.lines_of_code

      # Request Source
      self.pr_title = env.github.pr_title
      self.pr_body = env.github.pr_body
    end
  end
end
