# So much was ripped direct from CocoaPods-Core - thanks!

require 'danger/dangerfile_dsl'
require 'danger/standard_error'

module Danger
  class Dangerfile
    include Danger::Dangerfile::DSL

    attr_accessor :env, :warnings, :errors, :messages, :verbose

    # @return [Pathname] the path where the Dangerfile was loaded from. It is nil
    #         if the Dangerfile was generated programmatically.
    #
    attr_accessor :defined_in_file

    # @return [String] a string useful to represent the Dangerfile in a message
    #         presented to the user.
    #
    def to_s
      'Dangerfile'
    end

    # Iterates through the DSL's attributes, and table's the output
    def print_known_info
      puts "Danger v#{Danger::VERSION}"
      width = AvailableValues.all.map(&:to_s).map(&:length).max
      puts "DSL Attributes:"
      puts "-" * (width + 4)
      AvailableValues.all.each do |value|
        spaces = (width - value.to_s.length)
        puts "| #{value.to_s.blue}#{' ' * spaces} | #{self.send(value)}"
      end
      puts "-" * (width + 4)

      puts "Metadata:"
      puts "#{'SCM'.blue}      : #{env.scm.class}"
      puts "#{'Source'.blue}   : #{env.ci_source.class}"
      puts "           #{'Base commit'.blue} : #{env.ci_source.base_commit}" if env.ci_source.respond_to? :base_commit
      puts "           #{'HEAD commit'.blue} : #{env.ci_source.head_commit}" if env.ci_source.respond_to? :head_commit
      puts "           git diff  #{env.ci_source.base_commit} #{env.ci_source.head_commit}".yellow
      puts "#{'Requests'.blue} : #{env.request_source.class}"
      puts "\n\n"
    end

    # Parses the file at a path, optionally takes the content of the file for DI
    #
    def parse(path, contents = nil)
      print_known_info if verbose

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

      if contents.include?("puts")
        puts "You used `puts` in your Dangerfile. To print out text to GitHub use `message` instead"
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
  end
end
