require "danger/clients/rubygems_client"

module Danger
  HomeDirectoyError = Class.new(StandardError)

  class HomeKeeper
    DANGER_VERSION_FILE = ".danger_version".freeze

    def self.create_latest_version_file!
      return unless home_permission?

      IO.write danger_version_file_path, RubyGemsClient.latest_danger_version
    end

    def self.danger_outdated?
      return false unless File.exist?(danger_version_file_path)

      Gem::Version.new(latest_danger_version) > Gem::Version.new(Danger::VERSION)
    end

    # private

    def self.user_home_path
      File.expand_path(Dir.home(Etc.getlogin))
    end
    private_class_method :user_home_path

    def self.home_permission?
      File.writable?(user_home_path) && File.directory?(user_home_path)
    end
    private_class_method :home_permission?

    def self.danger_version_file_path
      File.expand_path(File.join(Dir.home(Etc.getlogin), DANGER_VERSION_FILE))
    end
    private_class_method :user_home_path

    def self.latest_danger_version
      IO.read(danger_version_file_path).rstrip!
    end
    private_class_method :latest_danger_version
  end
end
