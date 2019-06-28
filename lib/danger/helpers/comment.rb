module Danger
  class Comment
    attr_reader :id, :body

    def initialize(id, body, inline = nil)
      @id = id
      @body = body
      @inline = inline
    end

    def self.from_github(comment)
      self.new(comment["id"], comment["body"])
    end

    def self.from_gitlab(comment)
      if comment.respond_to?(:id) && comment.respond_to?(:body)
        type = comment.respond_to?(:type) ? comment.type : nil
        self.new(comment.id, comment.body, type == "DiffNote")
      else
        self.new(comment["id"], comment["body"], comment["type"] == "DiffNote")
      end
    end

    def generated_by_danger?(danger_id)
      body.include?("\"generated_by_#{danger_id}\"")
    end

    def inline?
      @inline.nil? ? body.include?("") : @inline
    end
  end
end
