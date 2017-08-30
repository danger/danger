require "danger/plugin_support/plugin"

module Danger
  # A way to interact with Danger herself. Offering APIs to import plugins,
  # and Dangerfiles from muliple sources.
  #
  # @example Import a plugin available over HTTP
  #
  #          device_grid = "https://raw.githubusercontent.com/fastlane/fastlane/master/danger-device_grid/lib/device_grid/plugin.rb"
  #          danger.import_plugin(device_grid)
  #
  # @example Import from a local file reference
  #
  #          danger.import_plugin("danger/plugins/watch_plugin.rb")
  #
  # @example Import all files inside a folder
  #
  #          danger.import_plugin("danger/plugins/*.rb")
  #
  # @example Run a Dangerfile from inside a sub-folder
  #
  #          danger.import_dangerfile(path: "path/to/Dangerfile")
  #
  # @example Run a Dangerfile from inside a gem
  #
  #          danger.import_dangerfile(gem: "ruby-grape-danger")
  #
  # @example Run a Dangerfile from inside a repo
  #
  #          danger.import_dangerfile(gitlab: "ruby-grape/danger")
  #
  # @example Run a Dangerfile from inside a repo branch and path
  #
  #          danger.import_dangerfile(github: "ruby-grape/danger", branch: "custom", path: "path/to/Dangerfile")
  #
  # @see  danger/danger
  # @tags core, plugins

  class DangerfileDangerPlugin < Plugin
    # The instance name used in the Dangerfile
    # @return [String]
    #
    def self.instance_name
      "danger"
    end

    # @!group Danger
    # Download a local or remote plugin and make it usable inside the Dangerfile.
    #
    # @param    [String] path_or_url
    #           a local path or a https URL to the Ruby file to import
    #           a danger plugin from.
    # @return   [void]
    #
    def import_plugin(path_or_url)
      raise "`import_plugin` requires a string" unless path_or_url.kind_of?(String)

      if path_or_url.start_with?("http")
        import_url(path_or_url)
      else
        import_local(path_or_url)
      end
    end

    # @!group Danger
    # Import a Dangerfile.
    #
    # @param    [Hash] opts
    # @option opts [String] :github GitHub repo
    # @option opts [String] :gitlab GitLab repo
    # @option opts [String] :gem Gem name
    # @option opts [String] :path Path to Dangerfile
    # @return   [void]
    def import_dangerfile(opts)
      if opts.kind_of?(String)
        warn "Use `import_dangerfile(github: '#{opts}')` instead of `import_dangerfile '#{opts}'`."
        import_dangerfile_from_github(opts)
      elsif opts.kind_of?(Hash)
        if opts.key?(:github) || opts.key?(:gitlab)
          import_dangerfile_from_github(opts[:github] || opts[:gitlab], opts[:branch], opts[:path])
        elsif opts.key?(:path)
          import_dangerfile_from_path(opts[:path])
        elsif opts.key?(:gem)
          import_dangerfile_from_gem(opts[:gem])
        else
          raise "`import` requires a Hash with either :github or :gem"
        end
      else
        raise "`import` requires a Hash" unless opts.kind_of?(Hash)
      end
    end

    # @!group Danger
    # Returns the name of the current SCM Provider being used.
    # @return [Symbol] The name of the SCM Provider used for the active repository.
    def scm_provider
      return :unknown unless env.request_source

      case env.request_source
      when Danger::RequestSources::GitHub
        :github
      when Danger::RequestSources::GitLab
        :gitlab
      when Danger::RequestSources::BitbucketServer
        :bitbucket_server
      when Danger::RequestSources::BitbucketCloud
        :bitbucket_cloud
      when Danger::RequestSources::VSTS
        :vsts
      else
        :unknown
      end
    end

    private

    # @!group Danger
    # Read and execute a local Dangerfile.
    #
    # @param    [String] path
    #           A path to a Dangerfile.
    # @return   [void]
    #
    def import_dangerfile_from_path(path)
      raise "`import_dangerfile_from_path` requires a string" unless path.kind_of?(String)
      local_path = File.join(path, "Dangerfile")
      @dangerfile.parse(Pathname.new(local_path))
    end

    # @!group Danger
    # Read and execute a Dangerfile from a gem.
    #
    # @param    [String] name
    #           The name of the gem that contains a Dangerfile.
    # @return   [void]
    #
    def import_dangerfile_from_gem(name)
      raise "`import_dangerfile_from_gem` requires a string" unless name.kind_of?(String)
      spec = Gem::Specification.find_by_name(name)
      import_dangerfile_from_path(spec.gem_dir)
    rescue Gem::MissingSpecError
      raise "`import_dangerfile_from_gem` tried to load `#{name}` and failed, did you forget to include it in your Gemfile?"
    end

    # @!group Danger
    # Download and execute a remote Dangerfile.
    #
    # @param    [String] slug
    #           A slug that represents the repo where the Dangerfile is.
    # @param    [String] branch
    #           A branch from repo where the Dangerfile is.
    # @param    [String] path
    #           The path at the repo where Dangerfile is.
    # @return   [void]
    #
    def import_dangerfile_from_github(slug, branch = nil, path = nil)
      raise "`import_dangerfile_from_github` requires a string" unless slug.kind_of?(String)
      org, repo = slug.split("/")
      download_url = env.request_source.file_url(organisation: org, repository: repo, branch: branch, path: path || "Dangerfile")
      local_path = download(download_url)
      @dangerfile.parse(Pathname.new(local_path))
    end

    # @!group Plugins
    # Download a local or remote plugin or Dangerfile.
    # This method will not import the file for you, use plugin.import instead
    #
    # @param    [String] path_or_url
    #           a local path or a https URL to the Ruby file to import
    #           a danger plugin from.
    # @return [String] The path to the downloaded Ruby file
    #
    def download(path_or_url)
      raise "`download` requires a string" unless path_or_url.kind_of?(String)
      raise "URL is not https, for security reasons `danger` only supports encrypted requests" if URI.parse(path_or_url).scheme != "https"

      require "tmpdir"
      require "faraday"

      @http_client ||= Faraday.new do |b|
        b.adapter :net_http
      end
      content = @http_client.get(path_or_url)

      path = File.join(Dir.mktmpdir, "temporary_danger.rb")
      File.write(path, content.body)
      return path
    end

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
        validate_file_contains_plugin!(file) do
          # Without the expand_path it would fail if the path doesn't start with ./
          require File.expand_path(file)
        end

        refresh_plugins
      end
    end

    # Raises an error when the given block does not register a plugin.
    def validate_file_contains_plugin!(file)
      plugin_count_was = Danger::Plugin.all_plugins.length
      yield

      if Danger::Plugin.all_plugins.length == plugin_count_was
        raise("#{file} doesn't contain any valid danger plugins.")
      end
    end
  end
end
