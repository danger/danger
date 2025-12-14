# frozen_string_literal: true

# Test handler classes for specs - defined outside RSpec block
module Danger
  module OutputRegistry
    module TestHandlers
      class TestCustomHandler < OutputHandler
        attr_reader :executed

        def execute
          @executed = true
        end
      end

      class AnotherTestHandler < OutputHandler
        def execute
          # no-op
        end
      end
    end
  end
end

RSpec.describe Danger::OutputRegistry::OutputHandlerRegistry do
  let(:registry) { described_class.new }
  let(:context) { double("context") }
  let(:violations) { { warnings: [], errors: [], messages: [] } }
  let(:test_handler_class) { Danger::OutputRegistry::TestHandlers::TestCustomHandler }
  let(:another_handler_class) { Danger::OutputRegistry::TestHandlers::AnotherTestHandler }

  before do
    registry.context = context
    registry.violations = violations
  end

  after do
    # Clean up custom handlers after each test
    described_class.reset_custom_handlers!
  end

  describe ".register" do
    it "registers a custom handler" do
      described_class.register(
        :test_handler,
        test_handler_class,
        platforms: %i(github)
      )

      expect(described_class.custom_handlers).to have_key(:test_handler)
    end

    it "stores handler metadata correctly" do
      described_class.register(
        :test_handler,
        test_handler_class,
        platforms: %i(github gitlab),
        description: "A test handler"
      )

      metadata = described_class.custom_handlers[:test_handler]
      expect(metadata[:class]).to eq(test_handler_class)
      expect(metadata[:platforms]).to eq(%i(github gitlab))
      expect(metadata[:description]).to eq("A test handler")
      expect(metadata[:include_in_defaults]).to eq(false)
    end

    it "accepts a single platform symbol" do
      described_class.register(
        :test_handler,
        test_handler_class,
        platforms: :github
      )

      metadata = described_class.custom_handlers[:test_handler]
      expect(metadata[:platforms]).to eq(%i(github))
    end

    it "converts platform names to symbols" do
      described_class.register(
        :test_handler,
        test_handler_class,
        platforms: %w(github gitlab)
      )

      metadata = described_class.custom_handlers[:test_handler]
      expect(metadata[:platforms]).to eq(%i(github gitlab))
    end

    it "supports include_in_defaults option" do
      described_class.register(
        :test_handler,
        test_handler_class,
        platforms: %i(github),
        include_in_defaults: true
      )

      metadata = described_class.custom_handlers[:test_handler]
      expect(metadata[:include_in_defaults]).to eq(true)
    end
  end

  describe ".unregister" do
    before do
      described_class.register(
        :test_handler,
        test_handler_class,
        platforms: %i(github)
      )
    end

    it "removes a registered handler" do
      described_class.unregister(:test_handler)

      expect(described_class.custom_handlers).not_to have_key(:test_handler)
    end

    it "returns the removed handler metadata" do
      result = described_class.unregister(:test_handler)

      expect(result[:class]).to eq(test_handler_class)
    end

    it "returns nil for non-existent handler" do
      result = described_class.unregister(:non_existent)

      expect(result).to be_nil
    end
  end

  describe ".reset_custom_handlers!" do
    before do
      described_class.register(:handler1, test_handler_class, platforms: %i(github))
      described_class.register(:handler2, another_handler_class, platforms: %i(gitlab))
    end

    it "clears all custom handlers" do
      described_class.reset_custom_handlers!

      expect(described_class.custom_handlers).to be_empty
    end
  end

  describe "#handler" do
    context "with custom handlers" do
      before do
        described_class.register(
          :test_handler,
          test_handler_class,
          platforms: %i(github)
        )
      end

      it "returns an instance of the custom handler" do
        handler = registry.handler(:test_handler)

        expect(handler).to be_a(test_handler_class)
      end

      it "passes context and violations to the handler" do
        handler = registry.handler(:test_handler)

        expect(handler.send(:context)).to eq(context)
        expect(handler.send(:violations)).to eq(violations)
      end
    end

    context "when custom handler overrides built-in" do
      before do
        described_class.register(
          :console,
          test_handler_class,
          platforms: %i(github)
        )
      end

      it "returns the custom handler instead of built-in" do
        handler = registry.handler(:console)

        expect(handler).to be_a(test_handler_class)
      end
    end

    it "returns built-in handlers when no custom override exists" do
      handler = registry.handler(:console)

      expect(handler).to be_a(Danger::OutputRegistry::Handlers::Universal::ConsoleHandler)
    end

    it "returns nil for non-existent handler" do
      handler = registry.handler(:non_existent)

      expect(handler).to be_nil
    end
  end

  describe "#available_handlers" do
    it "includes built-in handlers" do
      handlers = registry.available_handlers

      expect(handlers).to include(:console)
      expect(handlers).to include(:github_check)
    end

    it "includes custom handlers" do
      described_class.register(:test_handler, test_handler_class, platforms: %i(github))

      handlers = registry.available_handlers

      expect(handlers).to include(:test_handler)
    end

    it "does not duplicate handler names" do
      described_class.register(:console, test_handler_class, platforms: %i(github))

      handlers = registry.available_handlers

      expect(handlers.count(:console)).to eq(1)
    end
  end

  describe "#handlers_for_platform" do
    context "with custom handlers" do
      before do
        described_class.register(
          :github_only_handler,
          test_handler_class,
          platforms: %i(github)
        )
        described_class.register(
          :multi_platform_handler,
          another_handler_class,
          platforms: %i(github gitlab)
        )
      end

      it "includes custom handlers for matching platform" do
        handlers = registry.handlers_for_platform(:github)

        expect(handlers).to include(:github_only_handler)
        expect(handlers).to include(:multi_platform_handler)
      end

      it "excludes custom handlers for non-matching platform" do
        handlers = registry.handlers_for_platform(:bitbucket)

        expect(handlers).not_to include(:github_only_handler)
      end

      it "includes built-in handlers for the platform" do
        handlers = registry.handlers_for_platform(:github)

        expect(handlers).to include(:github_check)
        expect(handlers).to include(:console)
      end
    end
  end

  describe "#default_handlers_for_platform" do
    context "without include_in_defaults" do
      before do
        described_class.register(
          :test_handler,
          test_handler_class,
          platforms: %i(github),
          include_in_defaults: false
        )
      end

      it "does not include the custom handler" do
        handlers = registry.default_handlers_for_platform(:github)

        expect(handlers.map(&:class)).not_to include(test_handler_class)
      end
    end

    context "with include_in_defaults" do
      before do
        described_class.register(
          :test_handler,
          test_handler_class,
          platforms: %i(github),
          include_in_defaults: true
        )
      end

      it "includes the custom handler in defaults" do
        handlers = registry.default_handlers_for_platform(:github)

        expect(handlers.map(&:class)).to include(test_handler_class)
      end
    end

    context "with platform-specific defaults" do
      before do
        described_class.register(
          :github_default,
          test_handler_class,
          platforms: %i(github),
          include_in_defaults: true
        )
        described_class.register(
          :gitlab_default,
          another_handler_class,
          platforms: %i(gitlab),
          include_in_defaults: true
        )
      end

      it "only includes handlers for the requested platform" do
        github_handlers = registry.default_handlers_for_platform(:github)
        gitlab_handlers = registry.default_handlers_for_platform(:gitlab)

        expect(github_handlers.map(&:class)).to include(test_handler_class)
        expect(github_handlers.map(&:class)).not_to include(another_handler_class)

        expect(gitlab_handlers.map(&:class)).to include(another_handler_class)
        expect(gitlab_handlers.map(&:class)).not_to include(test_handler_class)
      end
    end
  end
end
