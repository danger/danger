require 'danger/plugin_support/plugin'

module Danger
  class DangerfileImportPlugin < Plugin
    # @!group Plugins
    # Download a local or remote plugin and use it locally
    #
    # @param    [String] path
    #           a local path or a https URL to the Ruby file to import
    #           a danger plugin from.
    def import(path)
      raise "`import` requires a string" unless path.kind_of?(String)
      path += ".rb" unless path.end_with?(".rb")

      if path.start_with?("http")
        import_url(path)
      else
        import_local(path)
      end
    end

    # @!group Plugins
    # Download a remote plugin and use it locally
    #
    # @param    [String] url
    #           https URL to the Ruby file to use
    def import_url(url)
      raise "URL is not https, for security reasons `danger` only supports encrypted requests" unless url.start_with?("https://")

      require 'tmpdir'
      require 'faraday'

      @http_client ||= Faraday.new do |b|
        b.adapter :net_http
      end
      content = @http_client.get(url)

      Dir.mktmpdir do |dir|
        path = File.join(dir, "temporary_remote_action.rb")
        File.write(path, content.body)
        import_local(path)
      end
    end

    # @!group Plugins
    # Import one or more local plugins
    #
    # @param    [String] path
    #           The path to the file to import
    #           Can also be a pattern (./**/*plugin.rb)
    def import_local(path)
      Dir[path].each do |file|
        require File.expand_path(file) # without the expand_path it would fail if the path doesn't start with ./
        refresh_plugins
      end
    end
  end
end
