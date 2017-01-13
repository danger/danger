# Find max_num_violations in lib/danger/comment_generators/github.md.erb.
class FindMaxNumViolations
  # Save ~ 5000 for contents other than violations to avoid exceeded 65536 max comment length limit.
  LIMIT = 60_000

  def initialize(violations)
    @violations = violations
  end

  def call
    total = 0
    num_of_violations_allowed = 0

    violations.each do |violation|
      message_length = violation.message.length + 80 # 80 is ~ the size of html wraps violation message.

      if total + message_length < LIMIT
        total += message_length
        num_of_violations_allowed += 1
      else
        break
      end
    end

    num_of_violations_allowed
  end

  private

  attr_reader :violations
end
