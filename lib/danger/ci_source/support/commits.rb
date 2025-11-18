# frozen_string_literal: true

module Danger
  class Commits
    def initialize(base_head)
      @base_head = base_head.strip.split(" ")
    end

    def base
      base_head.first
    end

    def head
      base_head.last
    end

    private

    attr_reader :base_head
  end
end
