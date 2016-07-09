class String
  def danger_class
    split("_").collect!(&:capitalize).join
  end

  def danger_pluralize(count)
    "#{count} #{self}#{'s' unless count == 1}"
  end

  def danger_underscore
    self.gsub(/::/, "/").
      gsub(/([A-Z]+)([A-Z][a-z])/, '\1_\2').
      gsub(/([a-z\d])([A-Z])/, '\1_\2').
      tr("-", "_").
      downcase
  end
end
