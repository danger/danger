if ["KrauseFx", "orta"].include?(pr_author) == false
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
  fail "Please provide a summary in the Pull Request description"
end

unless files_modified.any? { |a| a.include?("CHANGELOG.md") }
  fail "Please include a CHANGELOG entry"
end
