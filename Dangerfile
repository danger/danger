# Sometimes its a README fix, or something like that - which isn't relevant for
# including in a CHANGELOG for example

has_app_changes = !modified_files.grep(/lib/).empty?
has_test_changes = !modified_files.grep(/spec/).empty?

# Make a note about contributors not in the organization
octo_client = env.request_source.client
unless octo_client.organization_member?('danger', pr_author)
  message "@#{pr_author} is not a contributor yet, would you like to join the Danger org?"

  if modified_files.include?("*.gemspec")
    warn "External contributor has edited the Gemspec"
  end
end

if has_app_changes && !has_test_changes
  warn "Tests were not updated"
end

if pr_body.length < 5
  fail "Please provide a summary in the Pull Request description"
end

declared_trivial = (pr_title + pr_body).include?("#trivial") || !has_app_changes
if !modified_files.include?("CHANGELOG.md") && !declared_trivial
  fail("Please include a CHANGELOG entry. \nYou can find it at [CHANGELOG.md](https://github.com/danger/danger/blob/master/CHANGELOG.md).")
end

### Oddly enough, it's quite possible to do some testing of Danger, inside Danger
### So, you can ignore these, if you're looking at the Dangerfile to get ideas.

# If these are all empty something has gone wrong, better to raise it in a comment
if modified_files.empty? && added_files.empty? && deleted_files.empty?
  fail "This PR has no changes at all, this is likely a developer issue."
end

# This comes from `./danger_plugins/protect_files.rb` which is automatically parsed by Danger
files.protect_files(path: "danger.gemspec", message: ".gemspec modified", fail_build: false)
