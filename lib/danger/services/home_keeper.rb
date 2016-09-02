require "danger/clients/rubygems_client"

module Danger
  HomeDirectoyError = Class.new(StandardError)

  class HomeKeeper
    DANGER_VERSION_FILE = ".danger_version".freeze

    def self.check_home_permission!
      message = "There was error while trying to use your home path:"
      message += "\n * Your home directory #{user_home_path} is not writable" unless File.writable?(user_home_path)
      message += "\n * Your home directory #{user_home_path} is not a directory" unless File.directory?(user_home_path)
      raise Danger::HomeDirectoyError, message unless File.writable?(user_home_path) && File.directory?(user_home_path)
    end

    def self.create_latest_version_file!
      IO.write danger_version_file_path, RubyGemsClient.get_latest_danger_version
    end

    def self.is_danger_outdated?
      return false if !File.exist?(danger_version_file_path)

      Gem::Version.new(latest_danger_version) > Gem::Version.new(Danger::VERSION)
    end

    # private

    def self.user_home_path
      File.expand_path(Dir.home(Etc.getlogin))
    end
    private_class_method :user_home_path

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
