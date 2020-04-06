# Sometimes its a README fix, or something like that - which isn't relevant for
# including in a CHANGELOG for example
has_app_changes = !git.modified_files.grep(/lib/).empty?
has_test_changes = !git.modified_files.grep(/spec/).empty?
is_version_bump = git.modified_files.sort == ["CHANGELOG.md", "lib/danger/version.rb"].sort

if has_app_changes && !has_test_changes && !is_version_bump
  warn("Tests were not updated", sticky: false)
end

# Thanks other people!
message(":tada:") if is_version_bump && github.pr_author != "orta"

# Make a note about contributors not in the organization
unless github.api.organization_member?("danger", github.pr_author)
  # Pay extra attention if they modify the gemspec
  if git.modified_files.include?("*.gemspec")
    warn "External contributor has edited the Gemspec"
  end
end

# Mainly to encourage writing up some reasoning about the PR, rather than
# just leaving a title
if github.pr_body.length < 5
  fail "Please provide a summary in the Pull Request description"
end

# Let people say that this isn't worth a CHANGELOG entry in the PR if they choose
declared_trivial = (github.pr_title + github.pr_body).include?("#trivial") || !has_app_changes

if !git.modified_files.include?("CHANGELOG.md") && !declared_trivial
  fail("Please include a CHANGELOG entry. \nYou can find it at [CHANGELOG.md](https://github.com/danger/danger/blob/master/CHANGELOG.md).", sticky: false)
end

# Oddly enough, it's quite possible to do some testing of Danger, inside Danger
# So, you can ignore these, if you're looking at the Dangerfile to get ideas.
#
# If these are all empty something has gone wrong, better to raise it in a comment
if git.modified_files.empty? && git.added_files.empty? && git.deleted_files.empty?
  fail "This PR has no changes at all, this is likely an issue during development."
end

# This comes from `./danger_plugins/protect_files.rb` which is automatically parsed by Danger
files.protect_files(path: "danger.gemspec", message: ".gemspec modified", fail_build: false)

# Ensure that our core plugins all have 100% documentation
core_plugins = Dir.glob("lib/danger/danger_core/plugins/*.rb")
core_lint_output = `bundle exec yard stats #{core_plugins.join " "} --list-undoc --tag tags`

if !core_lint_output.include?("100.00%")
  # fail "The core plugins are not at 100% doc'd - see below:", sticky: false
  # markdown "```\n#{core_lint_output}```"
elsif core_lint_output.include? "warning"
  warn "The core plugins are have yard warnings - see below", sticky: false
  markdown "```\n#{core_lint_output}```"
end

unless ENV["RUNNING_IN_ACTIONS"]
  junit.parse "junit-results.xml"
  junit.headers = %i(file name)
  junit.report
end
