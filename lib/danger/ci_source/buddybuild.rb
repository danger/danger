module Danger
  # ### CI Setup
  # ### Token Setup
  class Buddybuild < CI
    def self.validates_as_ci?(env)
      false
    end

    def self.validates_as_pr?(env)
      false
    end

    def initialize(env)
    end

    def supported_request_sources
      @supported_request_sources ||= []
    end
  end
end
