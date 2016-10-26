class GetIgnoredViolation
  IGNORE_REGEXP = />*\s*danger\s*:\s*ignore\s*"(?<error>[^"]*)"/i

  def initialize(body)
    @body = body
  end

  def call
    return [] unless body

    body.chomp.scan(IGNORE_REGEXP).flatten
  end

  private

  attr_reader :body
end
