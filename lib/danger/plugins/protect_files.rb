module Danger
  class Dangerfile
    module DSL
      class ProtectFiles < Plugin
        def run(path: nil, message: nil, fail_build: true)
          raise "You have to provide a message" if message.to_s.length == 0
          raise "You have to provide a path" if path.to_s.length == 0

          broken_rule = false

          # TODO: This is currently broken: no access to env variables here
          Dir.glob(path) do |current|
            broken_rule = true if self.env.scm.modified_files.include?(current)
          end

          return unless broken_rule

          if fail_build
            @dsl.errors << message
          else
            @dsl.warnings << message
          end
        end

        def self.description
          [
            "Protect a file from being changed. This can",
            "be used in combination with some kind of",
            "permission check if a user is inside the org"
          ].join(" ")
        end
      end
    end
  end
end
