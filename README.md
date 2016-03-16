# Danger :no_entry_sign:

[![License](http://img.shields.io/badge/license-MIT-green.svg?style=flat)](https://github.com/orta/danger/blob/master/LICENSE)
[![Gem](https://img.shields.io/gem/v/danger.svg?style=flat)](http://rubygems.org/gems/danger)

Formalize your Pull Request etiquette.

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

## Getting Started

Add this line to your application's [Gemfile](https://guides.cocoapods.org/using/a-gemfile.html):

```ruby
gem 'danger'
```

To get up and running quickly, just run

```
bundle exec danger init
```

## Usage on CI

```
bundle exec danger
```

This will look at your `Dangerfile` and update the pull request accordingly. While you are setting up Danger, you may want to use: `--verbose` for more debug information.

## What happens?

Danger runs at the end of a CI build, she will execute a `Dangerfile`. This file is given some special variables based on the git diff and the Pull Request being running. You can use these variables in Ruby to provide messages, warnings and failures for your build. You set up Danger with a GitHub user account and she will post updates via comments on the Pull Request, and can fail your build too.

## DSL

&nbsp;  | &nbsp; | Danger :no_entry_sign:
-------------: | ------------- | ----
:sparkles: | `lines_of_code` | The total amount of lines of code in the diff
:pencil2:  | `modified_files` |  The list of modified files
:ship: | `added_files` | The list of added files
:recycle: | `deleted_files` | The list of removed files
:abc:  | `pr_title` | The title of the PR
:book:  | `pr_body` | The body of the PR
:busts_in_silhouette:  | `pr_author` | The author who submitted the PR
:bookmark: | `pr_labels` | The labels added to the PR

The `Dangerfile` is a ruby file, so really, you can do anything. However, at this stage you might need selling on the idea a bit more, so lets take some real examples:

#### Dealing with WIP pull requests

```ruby
# Sometimes its a README fix, or something like that - which isn't relevant for
# including in a CHANGELOG for example
declared_trivial = pr_title.include? "#trivial"

# Just to let people know
warn("PR is classed as Work in Progress") if pr_title.include? "[WIP]"
```

#### Being cautious around specific files

``` ruby
# Devs shouldn't ship changes to this file
fail("Developer Specific file shouldn't be changed") if modified_files.include?("Artsy/View_Controllers/App_Navigation/ARTopMenuViewController+DeveloperExtras.m")

# Did you make analytics changes? Well you should also include a change to our analytics spec
made_analytics_changes = modified_files.include?("/Artsy/App/ARAppDelegate+Analytics.m")
made_analytics_specs_changes = modified_files.include?("/Artsy_Tests/Analytics_Tests/ARAppAnalyticsSpec.m")
if made_analytics_changes
  fail("Analytics changes should have reflected specs changes") if !made_analytics_specs_changes

  # And pay extra attention anyway
  message('Analytics dict changed, double check for ?: `@""` on new entries')
  message('Also, double check the [Analytics Eigen schema](https://docs.google.com/spreadsheets/u/1/d/1bLbeOgVFaWzLSjxLOBDNOKs757-zBGoLSM1lIz3OPiI/edit#gid=497747862) if the changes are non-trivial.')
end
```

#### Pinging people when a specific file has changed

```ruby
message("@orta something changed in elan!") if modified_files.include? "/components/lib/variables/colors.json"
```

#### Exposing aspects of CI logs into the PR discussion

```ruby
build_log = File.read(File.join(ENV["CIRCLE_ARTIFACTS"], "xcode_test_raw.log"))
snapshots_url = build_log.match(%r{https://eigen-ci.s3.amazonaws.com/\d+/index.html})
fail("There were [snapshot errors](#{snapshots_url})") if snapshots_url
```

## Support

Danger currently is supported on Travis CI, Circle CI, BuildKite and Jenkins. These work via environment variables, so it's easy to extend to include your own.

## Advanced

You can access more detailed information by accessing the following variables

&nbsp; | Danger :no_entry_sign:
------------- | ----
`env.request_source.pr_json` | The full JSON for the pull request
`env.scm.diff` | The full [Diff](https://github.com/mojombo/grit/blob/master/lib/grit/diff.rb) file for the diff.
`env.ci_source` | To get information like the repo slug or pull request ID

These are considered implementation details though, and may be subject to change in future releases. We're very
open to turning useful bits into the official API.

## Test locally with `danger local`

Using `danger local` will look for the last merged pull request in your git history, and apply your current
`Dangerfile` against that Pull Request. Useful when editing.

## Suppress Violations

You can tell Danger to ignore a specific warning or error by commenting on the PR body:

```
> Danger: Ignore "Developer Specific file shouldn't be changed"
```

## Useful bits of knowledge

* You can set the base branch in the command line arguments see: `bundle exec danger --help`, if you commonly merge into non-master branches.
* Appending `--verbose` to `bundle exec danger` will expose all of the variables that Danger provides, and their values in the shell.

Here are some real-world Dangerfiles: [artsy/eigen](https://github.com/artsy/eigen/blob/master/Dangerfile), [danger/danger](https://github.com/danger/danger/blob/master/Dangerfile), [artsy/elan](https://github.com/artsy/elan/blob/master/Dangerfile) and more!

## License, Contributor's Guidelines and Code of Conduct

[Join our Slack Group](https://danger-slack.herokuapp.com/)

> This project is open source under the MIT license, which means you have full access to the source code and can modify it to fit your own needs.

> This project subscribes to the [Moya Contributors Guidelines](https://github.com/Moya/contributors) which TLDR: means we give out push access easily and often.

> Contributors subscribe to the [Contributor Code of Conduct](http://contributor-covenant.org/version/1/3/0/) based on the [Contributor Covenant](http://contributor-covenant.org) version 1.3.0.
