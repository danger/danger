RSpec::Matchers.define(:have_instance_variables) do |expected|
  match do |actual|
    expected.each do |instance_variable, expected_value|
      expect(actual.instance_variable_get(instance_variable)).to eq(expected_value)
    end
  end

  failure_message do |actual|
    expected.each do |instance_variable, expected_value|
      actual_value = actual.instance_variable_get(instance_variable)
      if actual_value != expected_value
        return "expected #{actual}#{instance_variable} to match #{expected_value}, but got #{actual_value}."
      end
    end
  end

  failure_message_when_negated do |actual|
    expected.each do |instance_variable, expected_value|
      actual_value = actual.instance_variable_get(instance_variable)
      if actual_value == expected_value
        return "expected #{actual}#{instance_variable} not to match #{expected_value}, but got #{actual_value}."
      end
    end
  end
end
