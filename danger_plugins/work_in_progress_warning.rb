# module Danger
#   class Dangerfile
#     module DSL
#       class WorkInProgressWarning < Plugin
#         def run
#           if (pr_body + pr_title).include?("WIP")
#             warn "Pull Request is Work in Progress"
#           end
#         end

#         def self.description
#           "Add a warning to PRs with 'WIP' in their title or body"
#         end
#       end
#     end
#   end
# end
