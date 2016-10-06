module Danger
  class RemoteInfo
    attr_reader :slug, :id

    def initialize(slug, id)
      @slug = slug
      @id = id
    end
  end
end
