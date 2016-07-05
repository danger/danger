require 'danger/plugin_support/plugin_parser'

module Danger
  describe PluginParser do
    it 'includes an example plugin' do
      parser = PluginParser.new 'spec/fixtures/plugins/example_broken.rb'
      parser.parse

      plugin_docs = parser.registry.at('Danger::Dangerfile::ExampleBroken')
      expect(plugin_docs).to be_truthy
    end

    it 'finds classes from inside the file' do
      parser = PluginParser.new 'spec/fixtures/plugins/example_broken.rb'
      parser.parse

      classes = parser.classes_in_file

      class_syms = classes.map(&:name)
      expect(class_syms).to eq [:Dangerfile, :ExampleBroken]
    end

    it 'skips non-subclasses of Danger::Plugin' do
      parser = PluginParser.new 'spec/fixtures/plugins/example_broken.rb'
      parser.parse

      plugins = parser.plugins_from_classes(parser.classes_in_file)

      class_syms = plugins.map(&:name)
      expect(class_syms).to eq []
    end

    it 'find subclasses of Danger::Plugin' do
      parser = PluginParser.new 'spec/fixtures/plugins/example_remote.rb'
      parser.parse

      plugins = parser.plugins_from_classes(parser.classes_in_file)

      class_syms = plugins.map(&:name)
      expect(class_syms).to eq [:ExampleRemote]
    end

    it 'outputs JSON for badly documented subclasses of Danger::Plugin' do
      parser = PluginParser.new 'spec/fixtures/plugins/example_remote.rb'
      parser.parse

      plugins = parser.plugins_from_classes(parser.classes_in_file)
      json = parser.to_dict(plugins)

      expect(json).to eq [{
        name: 'ExampleRemote',
        body_md: '',
        instance_name: 'example_remote',
        example_code: [],
        attributes: [],
        methods: [{ name: :echo, body_md: '', params: [], tags: [] }],
        tags: [],
        see: [],
        file: '/spec/fixtures/plugins/example_remote.rb'
      }]
    end

    it 'outputs JSON for well documented subclasses of Danger::Plugin' do
      parser = PluginParser.new 'spec/fixtures/plugins/example_fully_documented.rb'
      parser.parse

      plugins = parser.plugins_from_classes(parser.classes_in_file)
      json = parser.to_dict(plugins)

      expect(json).to eq [{
        name: 'DangerProselint',
        body_md:         "Lint markdown files inside your projects.\nThis is done using the [proselint](http://proselint.com) python egg.\nResults are passed out as a table in markdown.",
        instance_name: 'proselint',
        example_code:   [{ title: 'Specifying custom CocoaPods installation options', text: "\n# Runs a linter with comma style disabled\nproselint.disable_linters = [\"misc.scare_quotes\", \"misc.tense_present\"]\nproselint.lint_files \"_posts/*.md\"\n\n# Runs a linter with all styles, on modified and added markpown files in this PR\nproselint.lint_files" }],
        attributes: [
          { disable_linters: { read: nil, write:
            { name: :disable_linters=,
              body_md: "Allows you to disable a collection of linters from being ran.\nYou can get a list of [them here](https://github.com/amperser/proselint#checks)",
              params: [['value', nil]],
              tags: [] } } }
        ],

        methods: [
          {
            name: :lint_files,
            body_md: 'Lints the globbed files, which can fail your build if',
            params: [['files', 'nil']],
            tags: [
              { name: 'param', types: ['String'] },
              { name: 'return', types: ['void'] }
            ]
           },
          {
            name: :proselint_installed?,
            body_md: 'Determine if proselint is currently installed in the system paths.',
            params: [],
            tags: [{ name: 'return', types: ['Bool'] }]
        }
        ],
        tags: ['blogging, blog, writing, jekyll, middleman, hugo, metalsmith, gatsby, express'],
        see: ['artsy/artsy.github.io'],
        file: '/spec/fixtures/plugins/example_fully_documented.rb'
      }]
    end
  end
end
