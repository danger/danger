module Danger
  class Violation
    VALID_TYPES = %I[error warning message]
    attr_accessor :message, :sticky, :file, :line, :type

    def initialize(message, sticky, file = nil, line = nil, type: :warning)
      self.message = message
      self.sticky = sticky
      self.file = file
      self.line = line
      raise ArgumentError unless VALID_TYPES.include?(type)
      self.type = type
    end

    def ==(other)
      return false if other.nil?
      return false unless other.kind_of? self.class

      other.message == message &&
        other.sticky == sticky &&
        other.file == file &&
        other.line == line
    end

    def hash
      h = 1
      h = h * 31 + message.hash
      h = h * 13 + sticky.hash
      h = h * 17 + file.hash
      h = h * 17 + line.hash
      h
    end

    def eql?(other)
      return self == other
    end

    def <=>(other)
      types = VALID_TYPES + [:markdown]
      order = types.index(type) <=> types.index(other.type)
      return order unless order.zero?

      order = cmp_nils(file, other.file)
      return order unless order.nil?

      order = file <=> other.file if order.nil?
      return order unless order.zero?

      order = cmp_nils(line, other.line)
      return order unless order.nil?

      line <=> other.line
    end

    # compares a and b based entirely on whether one or the other is nil
    # arguments are in the same order as `a <=> b`
    # nil is sorted earlier - so cmp_nils(nil, 1) => -1
    #
    # If neither are nil, rather than returning `a <=> b` which would seem
    # like the obvious shortcut, `nil` is returned.
    # This allows us to distinguish between cmp_nils returning 0 for a
    # comparison of filenames, which means "a comparison on the lines is
    # meaningless - you cannot have a line number for a nil file - so they
    # should be sorted the same", and a <=> b returning 0, which means "the
    # files are the same, so compare on the lines"
    #
    # @return 0, 1, -1, or nil
    def cmp_nils(a, b)
      if a.nil? && b.nil?
        0
      elsif a.nil?
        -1
      elsif b.nil?
        1
      end
    end

    # @return [Boolean] returns true if is a file or line, false otherwise
    def inline?
      file || line
    end

    def to_s
      extra = []
      extra << "sticky: #{sticky}"
      extra << "file: #{file}" if file
      extra << "line: #{line}" if line
      extra << "type: #{type}"

      "Violation #{message} { #{extra.join ', '.freeze} }"
    end
  end
end
