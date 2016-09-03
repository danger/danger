module Danger
  class RubyGemsClient
    API_URL = "https://rubygems.org/api/v1/versions/danger/latest.json".freeze
    DUMMY_VERSION = "0.0.0".freeze

    def self.latest_danger_version
      require "json"
      json = JSON.parse(Faraday.get(API_URL).body)
      json.fetch("version") { DUMMY_VERSION }
    rescue StandardError => _e
      DUMMY_VERSION
    end
  end
end
