message("Lines #{lines_of_code}")
message("Added #{files_added}")
message("modified: #{files_modified}")
message("PR Body: '#{pr_body}'")
message("PR Title: '#{pr_title}'")

message("This pull request adds #{lines_of_code} new lines")

warn("Some random warning")

if ["KrauseFx", "orta"].include?(pr_author)
  message("Trusted author @#{pr_author}")
else
  warn("Author @#{pr_author} is not a contributor")
end

if pr_body.include?("WIP")
  warn("Pull Request is Work in Progress")
end

if modified.any? { |a| a.include?("spec") }
  message("Good, tests were actually modified")
else
  fail("There must be at least one new test or a modified test")
end
