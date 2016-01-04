if ["KrauseFx", "orta"].include?(pr_author)
  message("Trusted author @#{pr_author}")
else
  warn("Author @#{pr_author} is not a contributor")
end

if pr_body.include?("WIP")
  warn("Pull Request is Work in Progress")
end

if files_modified.any? { |a| a.include?("spec") }
  message("Good, tests were actually modified")
else
  fail("There must be at least one new test or a modified test")
end
