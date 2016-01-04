if ["KrauseFx", "orta"].include?(pr_author)
  message("Trusted author @#{pr_author}")
else
  warn("Author @#{pr_author} is not a contributor")
end

if pr_body.include?("WIP")
  warn("Pull Request is Work in Progress")
end

if files_modified.any? { |a| a.include?("spec") }
  message("Tests are updated / added")
else
  fail("There must be at least one new test or a modified test")
end

if pr_body.length < 5
  fail "Please provide a changelog summary in the Pull Request description @#{pr_author}"
end
