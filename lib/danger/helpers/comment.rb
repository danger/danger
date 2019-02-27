module Danger
  class Comment
    attr_reader :id, :body

    def initialize(id, body)
      @id = id
      @body = body
    end

    def self.from_github(comment)
      self.new(comment["id"], comment["body"])
    end

    def self.from_gitlab(comment)
      if comment.respond_to?(:id) && comment.respond_to?(:body)
        self.new(comment.id, comment.body)
      else
        self.new(comment["id"], comment["body"])
      end
    end

    def generated_by_danger?(danger_id)
      body.include?("\"generated_by_#{danger_id}\"")
    end

    def inline?
      body.include?("")
    end
  end
end
