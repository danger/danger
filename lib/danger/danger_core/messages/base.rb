module Danger
  class BaseMessage
    attr_accessor :message, :file, :line, :type

    def initialize(type:, message:, file: nil, line: nil)
      @type = type
      @message = message
      @file = file
      @line = line
    end

    def compare_by_file_and_line(other)
      order = cmp_nils(file, other.file)
      return order unless order.nil?

      order = file <=> other.file
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

    def eql?(other)
      return self == other
    end

    # @return [Boolean] returns true if is a file or line, false otherwise
    def inline?
      file || line
    end
  end
end
