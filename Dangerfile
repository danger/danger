if ["KrauseFx", "orta"].include?(pr_author)
  message("Trusted author @#{pr_author}")
else
  warn("Author @#{pr_author} is not a contributor")
end

if (pr_body + pr_title).include?("WIP")
  warn("Pull Request is Work in Progress")
end

if files_modified.any? { |a| a.include?("spec/") }
  message("Tests were updated / added")
else
  warn("Tests were not updated")
end

if pr_body.length < 5
  fail "Please provide a changelog summary in the Pull Request description @#{pr_author}"
end

unless files_modified.any? { |a| a.include?("CHANGELOG.md") }
  warn("Please include a CHANGELOG entry")
end

message files_modified
