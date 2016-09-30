class Dangerfile
  class ExampleBroken < Danger::Plugin
    def run
      return "Hi there"
    end
  end
end
