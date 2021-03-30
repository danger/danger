RSpec.describe Danger::DangerfileMessagingPlugin, host: :github do
  subject(:dangerfile) { testing_dangerfile }

  describe "#markdown" do
    it "adds single markdown" do
      dangerfile.parse(nil, "markdown('hello', file: 'foo.rb', line: 1)")
      markdown = added_messages(dangerfile, :markdowns).first

      expect(markdown.message).to eq("hello")
      expect(markdown.file).to eq("foo.rb")
      expect(markdown.line).to eq(1)
      expect(markdown.type).to eq(:markdown)
    end

    it "adds markdowns as array" do
      dangerfile.parse(nil, "markdown(['hello'], file: 'foo.rb', line: 1)")
      markdown = added_messages(dangerfile, :markdowns).first

      expect(markdown.message).to eq("hello")
      expect(markdown.file).to eq("foo.rb")
      expect(markdown.line).to eq(1)
      expect(markdown.type).to eq(:markdown)
    end

    it "adds multiple markdowns" do
      dangerfile.parse(nil, "markdown('hello', 'bye', file: 'foo.rb', line: 1)")
      markdowns = added_messages(dangerfile, :markdowns)

      expect(markdowns.first.message).to eq("hello")
      expect(markdowns.first.file).to eq("foo.rb")
      expect(markdowns.first.line).to eq(1)
      expect(markdowns.first.type).to eq(:markdown)

      expect(markdowns.last.message).to eq("bye")
      expect(markdowns.last.file).to eq("foo.rb")
      expect(markdowns.last.line).to eq(1)
      expect(markdowns.last.type).to eq(:markdown)
    end
  end

  describe "#message" do
    it "adds single message" do
      dangerfile.parse(nil, "message('hello', file: 'foo.rb', line: 1)")
      message = added_messages(dangerfile, :messages).first

      expect(message.message).to eq("hello")
      expect(message.file).to eq("foo.rb")
      expect(message.line).to eq(1)
      expect(message.type).to eq(:message)
    end

    it "adds messages as array" do
      dangerfile.parse(nil, "message(['hello'], file: 'foo.rb', line: 1)")
      message = added_messages(dangerfile, :messages).first

      expect(message.message).to eq("hello")
      expect(message.file).to eq("foo.rb")
      expect(message.line).to eq(1)
      expect(message.type).to eq(:message)
    end

    it "adds multiple messages" do
      dangerfile.parse(nil, "message('hello', 'bye', file: 'foo.rb', line: 1)")
      messages = added_messages(dangerfile, :messages)

      expect(messages.first.message).to eq("hello")
      expect(messages.first.file).to eq("foo.rb")
      expect(messages.first.line).to eq(1)
      expect(messages.first.type).to eq(:message)

      expect(messages.last.message).to eq("bye")
      expect(messages.last.file).to eq("foo.rb")
      expect(messages.last.line).to eq(1)
      expect(messages.last.type).to eq(:message)
    end

    it "does nothing when given a nil message" do
      dangerfile.parse(nil, "message(nil)")
      messages = added_messages(dangerfile, :messages)

      expect(messages).to be_empty
    end
  end

  describe "#warn" do
    it "adds single warning" do
      dangerfile.parse(nil, "warn('hello', file: 'foo.rb', line: 1)")
      warning = added_messages(dangerfile, :warnings).first

      expect(warning.message).to eq("hello")
      expect(warning.file).to eq("foo.rb")
      expect(warning.line).to eq(1)
      expect(warning.type).to eq(:warning)
    end

    it "adds warnings as array" do
      dangerfile.parse(nil, "warn(['hello'], file: 'foo.rb', line: 1)")
      warning = added_messages(dangerfile, :warnings).first

      expect(warning.message).to eq("hello")
      expect(warning.file).to eq("foo.rb")
      expect(warning.line).to eq(1)
      expect(warning.type).to eq(:warning)
    end

    it "adds multiple warnings" do
      dangerfile.parse(nil, "warn('hello', 'bye', file: 'foo.rb', line: 1)")
      warnings = added_messages(dangerfile, :warnings)

      expect(warnings.first.message).to eq("hello")
      expect(warnings.first.file).to eq("foo.rb")
      expect(warnings.first.line).to eq(1)
      expect(warnings.first.type).to eq(:warning)

      expect(warnings.last.message).to eq("bye")
      expect(warnings.last.file).to eq("foo.rb")
      expect(warnings.last.line).to eq(1)
      expect(warnings.last.type).to eq(:warning)
    end

    it "does nothing when given a nil warning" do
      dangerfile.parse(nil, "warn(nil)")
      warnings = added_messages(dangerfile, :warnings)

      expect(warnings).to be_empty
    end
  end

  describe "#fail" do
    it "adds single failure" do
      dangerfile.parse(nil, "fail('hello', file: 'foo.rb', line: 1)")
      failure = added_messages(dangerfile, :errors).first

      expect(failure.message).to eq("hello")
      expect(failure.file).to eq("foo.rb")
      expect(failure.line).to eq(1)
      expect(failure.type).to eq(:error)
    end

    it "adds failures as array" do
      dangerfile.parse(nil, "fail(['hello'], file: 'foo.rb', line: 1)")
      error = added_messages(dangerfile, :errors).first

      expect(error.message).to eq("hello")
      expect(error.file).to eq("foo.rb")
      expect(error.line).to eq(1)
      expect(error.type).to eq(:error)
    end

    it "adds multiple failures" do
      dangerfile.parse(nil, "fail('hello', 'bye', file: 'foo.rb', line: 1)")
      failures = added_messages(dangerfile, :errors)

      expect(failures.first.message).to eq("hello")
      expect(failures.first.file).to eq("foo.rb")
      expect(failures.first.line).to eq(1)
      expect(failures.first.type).to eq(:error)

      expect(failures.last.message).to eq("bye")
      expect(failures.last.file).to eq("foo.rb")
      expect(failures.last.line).to eq(1)
      expect(failures.last.type).to eq(:error)
    end

    it "does nothing when given a nil failure" do
      dangerfile.parse(nil, "fail(nil)")
      failures = added_messages(dangerfile, :errors)

      expect(failures).to be_empty
    end
  end

  describe "#status_report" do
    it "returns errors, warnings, messages and markdowns" do
      code = "fail('failure');" \
             "warn('warning');" \
             "message('message');" \
             "markdown('markdown')"

      dangerfile.parse(nil, code)

      expect(dangerfile.status_report).to eq(
        errors: ["failure"],
        warnings: ["warning"],
        messages: ["message"],
        markdowns: [markdown_factory("markdown")]
      )
    end
  end

  describe "#violation_report" do
    it "returns errors, warnings and messages" do
      code = "fail('failure');" \
             "warn('warning');" \
             "message('message');"

      dangerfile.parse(nil, code)

      expect(dangerfile.violation_report).to eq(
        errors: [violation_factory("failure")],
        warnings: [violation_factory("warning")],
        messages: [violation_factory("message")]
      )
    end
  end

  def added_messages(dangerfile, type)
    plugin = dangerfile.plugins.fetch(Danger::DangerfileMessagingPlugin)
    plugin.instance_variable_get("@#{type}")
  end
end
