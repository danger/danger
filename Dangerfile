# import "./danger_plugins/work_in_progress_warning"
import "https://raw.githubusercontent.com/danger/danger/remote-plugins/danger_plugins/work_in_progress_warning.rb"

# Sometimes its a README fix, or something like that - which isn't relevant for
# including in a CHANGELOG for example

has_app_changes = !modified_files.grep(/lib/).empty?
has_test_changes = !modified_files.grep(/spec/).empty?

if ["KrauseFx", "orta"].include?(pr_author) == false
  warn "Author @#{pr_author} is not a contributor"
  
  if modified_files.grep(/.gemspec/)
    warn "External contributors should not modify gemspec files"
  end
end

work_in_progress_warning

if has_app_changes && !has_test_changes
  warn "Tests were not updated"
end

if pr_body.length < 5
  fail "Please provide a summary in the Pull Request description"
end

declared_trivial = pr_title.include?("#trivial") || !has_app_changes
if !modified_files.include?("CHANGELOG.md") && !declared_trivial
  fail "Please include a CHANGELOG entry. \nYou can find it at [CHANGELOG.md](https://github.com/danger/danger/blob/master/CHANGELOG.md)."
end

### Oddly enough, it's quite possible to do some testing of Danger, inside Danger
### So, you can ignore these, if you're looking at the Dangerfile to get ideas.

# If these are all empty something has gone wrong, better to raise it in a comment
if modified_files.empty? && added_files.empty? && deleted_files.empty?
  fail "This PR has no changes at all, this is likely a developer issue."
end

protect_files(path: "danger.gemspec",
           message: ".gemspec modified",
        fail_build: false)
