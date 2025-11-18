# frozen_string_literal: true

module Danger
  class RepoInfo
    attr_reader :slug, :id

    def initialize(slug, id)
      @slug = slug
      @id = id
    end
  end
end
