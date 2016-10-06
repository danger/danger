module Danger
  class OpenPullRequest
    attr_reader :number, :title, :head, :base

    def initialize(number, title, head, base)
      @number = number
      @title = title
      @head = head
      @base = base
    end
  end
end
