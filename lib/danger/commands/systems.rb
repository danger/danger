module Danger
  class Systems < Runner
    self.abstract_command = true
    self.description = "For commands related to passing information from Danger to Danger.Systems."
    self.summary = "Create data for Danger.Systems."
  end

  class CIDocs < Systems
    self.command = "ci_docs"
    self.summary = "Outputs the up-to-date CI documentation for Danger."

    def run
      here = File.dirname(__FILE__)
      ci_source_paths = Dir.glob(here + "/../ci_source/*.rb")

      require "yard"
      # Pull out all the Danger::CI subclasses docs
      registry = YARD::Registry.load(ci_source_paths, true)
      ci_sources = begin
        registry.all(:class)
          .select { |klass| klass.inheritance_tree.map(&:name).include? :CI }
          .reject { |source| source.name == :CI }
          .reject { |source| source.name == :LocalGitRepo }
      end

      # Fail if anything is added and not documented
      cis_without_docs = ci_sources.select { |source| source.base_docstring.empty? }
      unless cis_without_docs.empty?
        cork.puts "Please add docs to: #{cis_without_docs.map(&:name).join(', ')}"
        abort("Failed.".red)
      end

      # Output a JSON array of name and details
      require "json"
      cork.puts ci_sources.map { |ci|
        {
          name: ci.name,
          docs: ci.docstring
        }
      }.to_json
    end
  end
end
