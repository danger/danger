require "danger/plugin_support/plugin"

module Danger
  # One way to support internal plugins is via `plugin.import` this gives you
  # the chance to quickly iterate without the need for building rubygems. As such,
  # it does not have the stringent rules around documentation expected of a public plugin.
  # It's worth noting, that you can also have plugins inside `./danger_plugins` and they
  # will be automatically imported into your Dangerfile at launch.
  #
  # @example Import a plugin available over HTTP
  #
  #          device_grid = "https://raw.githubusercontent.com/fastlane/fastlane/master/danger-device_grid/lib/device_grid/plugin.rb"
  #          plugin.import device_grid
  #
  # @example Import from a local file reference
  #
  #          plugin.import "danger/plugins/watch_plugin.rb"
  #
  # @example Import all files inside a folder
  #
  #          plugin.import "danger/plugins/*.rb"
  #
  # @see  danger/danger
  # @tags core, plugins

  class DangerfileImportPlugin < Plugin
    def self.instance_name
      "plugin"
    end

    # @!group Plugins
    # Download a local or remote plugin and use it inside the Dangerfile.
    #
    # @param    [String] path
    #           a local path or a https URL to the Ruby file to import
    #           a danger plugin from.
    # @return [void]

    def import(path_or_url)
      raise "`import` requires a string" unless path_or_url.kind_of?(String)

      if path_or_url.start_with?("http")
        import_url(path_or_url)
      else
        import_local(path_or_url)
      end
    end

    # @!group Plugins
    # Download a local or remote plugin or Dangerfile
    # This method will not import the file for you, use plugin.import instead
    #
    # @param    [String] path
    #           a local path or a https URL to the Ruby file to import
    #           a danger plugin from.
    # @return [String] The path to the downloaded Ruby file

    def download(path_or_url)
      raise "`download` requires a string" unless path_or_url.kind_of?(String)
      raise "URL is not https, for security reasons `danger` only supports encrypted requests" unless path_or_url.start_with?("https://")

      require "tmpdir"
      require "faraday"

      @http_client ||= Faraday.new do |b|
        b.adapter :net_http
      end
      content = @http_client.get(path_or_url)

      path = File.join(Dir.mktmpdir, "temporary_danger")
      File.write(path, content.body)
      return path
    end

    private

    # @!group Plugins
    # Download a remote plugin and use it locally.
    #
    # @param    [String] url
    #           https URL to the Ruby file to use
    # @return [void]
    def import_url(url)
      path = download(url)
      import_local(path)
    end

    # @!group Plugins
    # Import one or more local plugins.
    #
    # @param    [String] path
    #           The path to the file to import
    #           Can also be a pattern (./**/*plugin.rb)
    # @return [void]
    def import_local(path)
      Dir[path].each do |file|
        # Without the expand_path it would fail if the path doesn't start with ./
        require File.expand_path(file)
        refresh_plugins
      end
    end
  end
end
