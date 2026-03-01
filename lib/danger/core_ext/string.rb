class String
  # @return [String] the plural form of self determined by count
  def danger_pluralize(count)
    "#{count} #{self}#{'s' unless count == 1}"
  end

  # @return [String] converts to underscored, lowercase form
  def danger_underscore
    self.gsub(/::/, "/".freeze).
      gsub(/([A-Z]+)([A-Z][a-z])/, '\1_\2'.freeze).
      gsub(/([a-z\d])([A-Z])/, '\1_\2'.freeze).
      tr("-".freeze, "_".freeze).
      downcase
  end

  # @return [String] truncates string with ellipsis when exceeding the limit
  def danger_truncate(limit)
    length > limit ? "#{self[0...limit]}..." : self
  end
end
