# Documentation Overview

### git

Handles interacting with git inside a Dangerfile. Providing access to files that have changed, and useful statistics. Also provides
access to the commits in the form of [Git::Log](https://github.com/schacon/ruby-git/blob/master/lib/git/log.rb) objects.

<blockquote>Do something to all new and edited markdown files
  <pre>
markdowns = (git.added_files + git.modified_files)
do_something markdowns.select{ |file| file.end_with? "md" }</pre>
</blockquote>

<blockquote>Don't allow a file to be deleted
  <pre>
deleted = git.deleted_files.include? "my/favourite.file"
fail "Don't delete my precious" if deleted</pre>
</blockquote>

<blockquote>Fail really big diffs
  <pre>
fail "We cannot handle the scale of this PR" if git.lines_of_code > 50_000</pre>
</blockquote>

<blockquote>Warn when there are merge commits in the diff
  <pre>
if commits.any? { |c| c.message =~ /^Merge branch 'master'/ }
   warn 'Please rebase to get rid of the merge commits in this PR'
end</pre>
</blockquote>




#### Methods



`instance_name`



`initialize`

Paths for files that were added during the diff

`added_files`

Paths for files that were removed during the diff

`deleted_files`

Paths for files that changed during the diff

`modified_files`

The overall lines of code added/removed in the diff

`lines_of_code`

The overall lines of code removed in the diff

`deletions`

The overall lines of code added in the diff

`insertions`

The log of commits inside the diff

`commits`




### github

Handles interacting with GitHub inside a Dangerfile. Provides a few functions which wrap `pr_json` and also
through a few standard functions to simplify your code.

<blockquote>Warn when a PR is classed as work in progress
  <pre>
warn "PR is classed as Work in Progress" if github.pr_title.include? "[WIP]"</pre>
</blockquote>

<blockquote>Ensure that labels have been used on the PR
  <pre>
fail "Please add labels to this PR" if github.labels.empty?</pre>
</blockquote>

<blockquote>Check if a user is in a specific GitHub org, and message them if so
  <pre>
unless github.api.organization_member?('danger', github.pr_author)
  message "@#{pr_author} is not a contributor yet, would you like to join the Danger org?"
end</pre>
</blockquote>

<blockquote>Ensure there is a summary for a PR
  <pre>
fail "Please provide a summary in the Pull Request description" if github.pr_body.length < 5</pre>
</blockquote>




#### Methods



`initialize`



`instance_name`

The title of the Pull Request.

`pr_title`

The body text of the Pull Request.

`pr_body`

The username of the author of the Pull Request.

`pr_author`

The labels assigned to the Pull Request.

`pr_labels`

The branch to which the PR is going to be merged into.

`branch_for_base`

The branch to which the PR is going to be merged from.

`branch_for_head`

The base commit to which the PR is going to be merged as a parent.

`base_commit`

The head commit to which the PR is requesting to be merged from.

`head_commit`

The hash that represents the PR's JSON. For an example of what this looks like
see the [Danger Fixture'd one](https://raw.githubusercontent.com/danger/danger/master/spec/fixtures/pr_response.json).

`pr_json`

Provides access to the GitHub API client used inside Danger. Making
it easy to use the GitHub API inside a Dangerfile.

`api`




### plugin

One way to support internal plugins is via `plugin.import` this gives you
the chance to quickly iterate without the need for building rubygems. As such,
it does not have the stringent rules around documentation expected of a public plugin.
It's worth noting, that you can also have plugins inside `./danger_plugins` and they
will be automatically imported into your Dangerfile at launch.

<blockquote>Import a plugin available over HTTP
  <pre>
device_grid = "https://raw.githubusercontent.com/fastlane/fastlane/master/danger-device_grid/lib/device_grid/plugin.rb"
plugin.import device_grid</pre>
</blockquote>

<blockquote>Import from a local file reference
  <pre>
plugin.import "danger/plugins/watch_plugin.rb"</pre>
</blockquote>

<blockquote>Import all files inside a folder
  <pre>
plugin.import "danger/plugins/*.rb"</pre>
</blockquote>




#### Methods



`instance_name`

Download a local or remote plugin and use it inside the Dangerfile.

`import`




### messaging

Provides the feedback mechanism for Danger. Danger can keep track of
messages, warnings, failure and post arbitrary markdown into a comment.

The message within which Danger communicates back is amended on each run in a session.

Each of `message`, `warn` and `fail` have a `sticky` flag, `true` by default, which
means that the message will be crossed out instead of being removed. If it's not use on
subsequent runs.

By default, using `fail` would fail the corresponding build. Either via an API call, or
via the return value for the danger command.

It is possible to have Danger ignore specific warnings or errors by writing `Danger: Ignore "[warning/error text]`.

Sidenote: Messaging is the only plugin which adds functions to the root of the Dangerfile.

<blockquote>Failing a build
  <pre>
fail "This build didn't pass tests"</pre>
</blockquote>

<blockquote>Failing a build, but not keeping it's value around on subsequent runs
  <pre>
fail("This build didn't pass tests", sticky: false)</pre>
</blockquote>

<blockquote>Passing a warning
  <pre>
warn "This build didn't pass linting"</pre>
</blockquote>

<blockquote>Displaying a markdown table
  <pre>
message = "### Proselint found issues\n\n"
message << "Line | Message | Severity |\n"
message << "| --- | ----- | ----- |\n"
message << "20 | No documentation | Error \n"
markdown message</pre>
</blockquote>




#### Methods



`initialize`



`instance_name`

Print markdown to below the table

`markdown`

Print out a generate message on the PR

`message`

Specifies a problem, but not critical

`warn`

Declares a CI blocking error

`fail`

A list of all messages passed to Danger, including
the markdowns.

`status_report`

A list of all violations passed to Danger, we don't
anticipate users of Danger needing to use this.

`violation_report`



