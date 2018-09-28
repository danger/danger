require "danger/plugin_support/plugin"

# Danger
module Danger
  # Handles interacting with local only plugin inside a Dangerfile.
  # It is support pluggin for dry_run command and does not expose any methods.
  # But you can still use other plugins like git
  #
  # @example Check that added lines contains agreed form of words 
  #
  #       git.diff.each do |chunk|
  #         chunk.patch.lines.grep(/^+/).each do |added_line|
  #           if added_line.gsub!(/(?<cancel>cancel)(?<rest>[^l[[:space:]][[:punct:]]]+)/i, '>>\k<cancel>-l-\k<rest><<')
  #             fail "Single 'L' for cancellation-alike words in '#{added_line}'" 
  #           end
  #         end
  #       end
  #
  # @see  danger/danger
  # @tags core, local_only
  #
  class DangerfileLocalOnlyPlugin < Plugin
    # So that this init can fail.
    def self.new(dangerfile)
      return nil if dangerfile.env.request_source.class != Danger::RequestSources::LocalOnly
      super
    end

    def initialize(dangerfile)
      super(dangerfile)

      @local_repo = dangerfile.env.request_source
    end

    # The instance name used in the Dangerfile
    # @return [String]
    #
    def self.instance_name
      "local_repo"
    end
  end
end
