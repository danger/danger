# So much was ripped direct from CocoaPods-Core - thanks!

require 'danger/dangerfile_dsl'
require 'danger/standard_error'

module Danger
  class Dangerfile
    include Danger::Dangerfile::DSL

    attr_accessor :env, :warnings, :errors, :messages, :markdowns, :verbose

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
      rows = []

      AvailableValues.all.each do |key|
        value = self.send(key)
        value = value.scan(/.{,80}/).to_a.each(&:strip!).join("\n") if key == :pr_body

        # So that we either have one value per row
        # or we have [] for an empty array
        value = value.join("\n") if value.kind_of?(Array) && value.count > 0

        rows << [key.to_s, value]
      end

      rows << ["---", "---"]
      rows << ["SCM", env.scm.class]
      rows << ["Source", env.ci_source.class]
      rows << ["Requests", env.request_source.class]
      rows << ["Base Commit", env.meta_info_for_base]
      rows << ["Head Commit", env.meta_info_for_head]

      params = {}
      params[:rows] = rows.each { |current| current[0] = current[0].yellow }
      params[:title] = "Danger v#{Danger::VERSION}\nDSL Attributes".green

      puts ""
      puts Terminal::Table.new(params)
      puts ""
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
