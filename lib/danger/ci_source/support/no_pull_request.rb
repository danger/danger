# frozen_string_literal: true

module Danger
  class NoPullRequest
    def valid?
      false
    end
  end
end
