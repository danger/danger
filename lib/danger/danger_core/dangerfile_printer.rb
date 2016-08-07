# Handles outputting the Danger output to the terminal
# e.g. all the warnings, errors & markdowns

module Danger
  class DangerfilePrinter
    def initialize(messaging, ui)
      @messaging = messaging
      @ui = ui
    end

    def print_results
      status = @messaging.status_report
      return if (status[:errors] + status[:warnings] + status[:messages] + status[:markdowns]).count.zero?

      @ui.section("Results:") do
        [:errors, :warnings, :messages].each do |key|
          formatted = key.to_s.capitalize + ":"
          title = case key
                  when :errors
                    formatted.red
                  when :warnings
                    formatted.yellow
                  else
                    formatted
                  end
          rows = status[key]
          print_list(title, rows)
        end

        if status[:markdowns].count > 0
          @ui.section("Markdown:") do
            status[:markdowns].each do |current_markdown|
              @ui.puts current_markdown
            end
          end
        end
      end
    end

    private

    def print_list(title, rows)
      @ui.title(title) do
        rows.each do |row|
          @ui.puts("- [ ] #{row}")
        end
      end unless rows.empty?
    end
  end
end
