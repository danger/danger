require "danger/danger_core/dangerfile_printer"

describe Danger::DangerfilePrinter do
  describe "#print_results" do
    it "Prints out 3 lists" do
      code = "message 'A message'\n" \
             "warn 'Another warning'\n" \
             "warn 'A warning'\n" \
             "fail 'Another error'\n" \
             "fail 'An error'\n"
      dm = testing_dangerfile

      plugin_host = Danger::PluginHost.new
      plugin_host.refresh_plugins(dm)

      dm.parse Pathname.new(""), code

      messaging = plugin_host.external_plugins.first { |plugin| plugin.is_kind? Danger::DangerfileMessagingPlugin }

      printer = Danger::DangerfilePrinter.new(messaging, dm.ui)

      expect(printer).to receive(:print_list).with("Errors:".red, ["Another error", "An error"])
      expect(printer).to receive(:print_list).with("Warnings:".yellow, ["Another warning", "A warning"])
      expect(printer).to receive(:print_list).with("Messages:", ["A message"])

      printer.print_results
    end
  end

  describe "verbose" do
    it "outputs metadata when verbose" do
      file = make_temp_file ""
      dm = testing_dangerfile
      dm.verbose = true

      expect(dm).to receive(:print_known_info)
      dm.parse file.path
    end

    it "does not print metadata by default" do
      file = make_temp_file ""
      dm = testing_dangerfile

      expect(dm).to_not receive(:print_known_info)
      dm.parse file.path
    end
  end
end
