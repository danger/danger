is_trusted_author = ["KrauseFx", "orta"].include?(pr_author)

if (pr_body + pr_title).include?("WIP")
  warn("Pull Request is Work in Progress")
end

# Verify that there have been tests?
if files_modified.any? { |a| a.include?("spec") }
  message("Tests were updated / added")
else
  if is_trusted_author
    # I guess we can trust us?
    warn("Tests were not updated")
  else
    fail("Tests were not updated")
  end
end

if pr_body.length < 5
  fail "Please provide a changelog summary in the Pull Request description @#{pr_author}"
end
