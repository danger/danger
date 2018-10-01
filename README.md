# Danger :no_entry_sign:

[![License](http://img.shields.io/badge/license-MIT-green.svg?style=flat)](https://github.com/orta/danger/blob/master/LICENSE)
[![Gem](https://img.shields.io/gem/v/danger.svg?style=flat)](http://rubygems.org/gems/danger)
[![Travis CI](https://img.shields.io/travis/danger/danger.svg?style=flat)](https://travis-ci.org/danger/danger)
[![Join the community on Spectrum](https://withspectrum.github.io/badge/badge.svg)](https://spectrum.chat/danger)

Formalize your Pull Request etiquette.

-------

<p align="center">
    <a href="#what-is-danger">What is Danger?</a> &bull;
    <a href="VISION.md">Vision</a> &bull;
    <a href="#im-here-to-help-out">Helping Out</a> &bull;
    <a href="https://danger.systems/guides/creating_your_first_plugin.html">Plugin Development</a>
</p>

-------

## What is Danger?

Danger runs after your CI, automating your team's conventions surrounding code review.

This provides another logical step in your process, through this Danger can help lint your rote tasks in daily code review.

You can use Danger to codify your team's norms, leaving humans to think about harder problems.

## For example?

You can:

* Enforce CHANGELOGs
* Enforce links to Trello/JIRA in PR/MR bodies
* Enforce using descriptive labels
* Look out for common anti-patterns
* Highlight interesting build artifacts
* Give specific files extra focus

Danger provides the glue to let _you_ build out the rules specific to your team's culture, offering useful metadata and a comprehensive plugin system to share common issues.

## Getting Started

Alright. So, actually, you may be in the wrong place. From here on in, this README is going to be for people who are interested in working on and improving on Danger.

We keep all of the end-user documentation at [https://danger.systems](https://danger.systems).

Some quick links: [Guides Index](https://danger.systems/guides.html), [DSL Reference](https://danger.systems/reference.html), [Getting Started](https://danger.systems/guides/getting_started.html) and [What does Danger Do?](https://danger.systems/guides/what_does_danger_do.html).

## I'm here to help out!

Brilliant. So, let's get you set up.

``` sh
git clone https://github.com/danger/danger.git
cd danger
bundle install
bundle exec rake spec
```

This sets everything up and runs all of the tests.

#### Theory

Danger has a [VISION.md](https://github.com/danger/danger/blob/master/VISION.md) file, which sums up the ideas around what Danger is. It is the lower bounds of what Danger means. Orta has written on handling and creating Danger [on the Artsy blog](http://artsy.github.io/blog/categories/danger/), too.

#### Documentation

The code you write may end up in the public part of the website — the easiest way to tell is that it is vastly overdocumented. If you are working in a space that looks over-documented, please be extra considerate to add documentation. We expect the consumers of that documentation to be non-rubyists, thus you should avoid specific jargon and try to provide duplicate overlapping examples.

#### Testing

So far, we've not really figured out the right way to make tests for our CLI commands. When we have done so, they've ended up being brittle. So, ideally, try to move any logic that would go into a command into separate classes, and test those. We're okay with the command not having coverage, but ideally the classes that make up what it does will.

I'd strongly recommend using `bundle exec guard` to run your tests as you work. Any changes you make in the lib, or specs will have corresponding tests run instantly.

#### Debugging

Ruby is super dynamic. One of the best ways to debug Ruby code is by using [pry](http://pryrepl.org/). We include pry for developers: when you have a problem, copy these two lines just before your problem and follow the instructions from "[I Want To Be A Danger Wizard](https://danger.systems/guides/troubleshooting.html#i-want-to-be-a-danger-wizard)."

```ruby
require 'pry'
binding.pry
```

## License, Contributor's Guidelines and Code of Conduct

We try to keep as much discussion as possible in GitHub issues, but also have a pretty inactive Slack --- if you'd like an invite, ping [@Orta](https://twitter.com/orta/) a DM on Twitter with your email. It's mostly interesting if you want to stay on top of Danger without all the emails from GitHub.

> This project is open source under the MIT license, which means you have full access to the source code and can modify it to fit your own needs.

> This project subscribes to the [Moya Contributors Guidelines](https://github.com/Moya/contributors) which TLDR: means we give out push access easily and often.

> Contributors subscribe to the [Contributor Code of Conduct](http://contributor-covenant.org/version/1/3/0/) based on the [Contributor Covenant](http://contributor-covenant.org) version 1.3.0.
