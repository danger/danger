# Danger :no_entry_sign:

[![License](http://img.shields.io/badge/license-MIT-green.svg?style=flat)](https://github.com/orta/danger/blob/master/LICENSE)
[![Gem](https://img.shields.io/gem/v/danger.svg?style=flat)](http://rubygems.org/gems/danger)

Formalize your Pull Request etiquette.

*Note:* Not ready for public usage yet. Work in progress

-------
<p align="center">
    <a href="#installation">Installation</a> &bull; 
    <a href="#usage">Usage</a> &bull; 
    <a href="#dsl">DSL</a> &bull; 
    <a href="#constraints">Constraints</a> &bull; 
    <a href="#advanced">Advanced</a> &bull; 
    <a href="#contributing">Contributing</a>
</p>

-------

## Installation

Add this line to your application's [Gemfile](https://guides.cocoapods.org/using/a-gemfile.html):

```ruby
gem 'danger'
```

and then run the following to set up `danger` for your repository

```
danger init
```

## Usage

In CI run `bundle exec danger`.  This will look at your `Dangerfile` and provide some feedback based on that.

## DSL

&nbsp;  | &nbsp; | Danger :no_entry_sign:
-------------: | ------------- | ----
:sparkles: | `lines_of_code` | The total amount of lines of code in the diff
:pencil2:  | `files_modified` |  The list of files modified
:ship: | `files_added` | The list of files added
:recycle: | `files_removed` | The list of files removed
:abc:  | `pr_title` | The title of the PR
:book:  | `pr_body` | The body of the PR
:busts_in_silhouette:  | `pr_author` | The author who submitted the PR

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

message("This pull request adds #{lines_of_code} new lines")
warn("Author @#{pr_author} is not a contributor") unless ["KrauseFx", "orta"].include?(pr_author)
```

## Constraints

* **GitHub** - Built with same-repo PRs in mind
* **Git** - Built with master as the merge branch

## Advanced

You can access more detailed information by accessing the following variables

&nbsp; | Danger :no_entry_sign:
------------- | ----
`env.github.pr_json` | The full JSON for the pull request
`env.git.diff` | The full [GitDiff](https://github.com/schacon/ruby-git/blob/master/lib/git/diff.rb) file for the diff.
`env.ci_source` | To get information like the repo slug or pull request ID

## Special Thanks

Thanks [@orta](https://twitter.com/orta) for starting this project and handing it over to the `fastlane` organisation

## License

> This project and all fastlane tools are in no way affiliated with Apple Inc. This project is open source under the MIT license, which means you have full access to the source code and can modify it to fit your own needs. All fastlane tools run on your own computer or server, so your credentials or other sensitive information will never leave your own computer. You are responsible for how you use fastlane tools.
