# Danger :no_entry_sign:

Formalize your Pull Request etiquette.

## Installation

Add this line to your application's [Gemfile](https://guides.cocoapods.org/using/a-gemfile.html):

```ruby
gem 'danger'
```

## Usage

In CI run `bundle exec danger`.  This will look at your `Dangerfile` and provide some feedback based on that

## DSL

Danger :no_entry_sign:  | &nbsp; | &nbsp;
-------------: | ------------- | ----
:sparkles: | `lines_of_code` | The total amount of lines of code in the diff
:monorail: | `files_modified` |  The list of files modified
:ship: | `files_added` | The list of files added
:pencil2: | `files_removed` | The list of files removed
:wrench: | `pr_title` | The title of the PR
:thought_balloon: | `pr_body` | The body of the PR



You can access more detailed information  by looking through:

Danger :no_entry_sign:  | &nbsp; | &nbsp;
-------------: | ------------- | ----
| :sparkles: |  `env.travis` | Details on the travis integration
| :tophat: |`env.circle` |  Details on the circle integration
| :octocat: | `env.github.pr_json` | The full JSON for the pull request
| :ghost: | `env.git.diff` | The full [GitDiff](https://github.com/schacon/ruby-git/blob/master/lib/git/diff.rb) file for the diff.

You can then create a `Dangerfile` like the following:

``` ruby
# Easy checks
warn("PR is classed as Work in Progress") if pr_title.include? "[WIP]"

if lines_of_code > 50 && files_modified.include? "CHANGELOG.yml" == false
  fail("No CHANGELOG changes made")
end

# Stop skipping some manual testing
if lines_of_code > 50 && pr_title.include? "📱" == false
   fail("Needs testing on a Phone if change is non-trivial")
end
```

## Constraints

* **GitHub** - Built with same-repo PRs in mind
* **Git** - Built with master as the merge branch

PRs welcome on these

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/orta/danger.
