---
title: Frequently Asked Questions
subtitle: FAQ
layout: guide
order: 6
---

#### Can I run Danger on my computer to test?

Yep! Use `danger local`. If you want to get into a debug REPL, use `danger local --pry`. You can find more on the [troubleshooting guide](/guides/troubleshooting.html)

#### I want to ignore a fail, just this once

You can tell Danger to ignore a specific warning or error by commenting on the body of your code review body:

```
> Danger: Ignore "Developer Specific file shouldn't be changed"
```

Then Danger would not show that message, and would not fail the build if it were the only `fail`.


#### I want to run Danger across multiple repos

For any significant number of repos we recommend you package your Dangerfile in a gem, release it and use it via `danger.import_dangerfile(gem: "name")`. This allows you to specify versioned plugin dependencies and share rules.

See [ruby-grape/danger](https://github.com/ruby-grape/danger) for an example.

Alternatively you can also use a shared Dangerfile and import it via `danger.import_dangerfile(github: "org/repo")`. Assuming Danger can reach the other repo, she will download the Dangerfile from that repo and parse it in-place.

This gives access to the same local and other environment variables.

#### Multiple Dangers

You can have each instance of Danger running on a different CI provider and even doing different validations. An use case would be:

* `basic` runs on a Linux environment (such as Circle CI) and validates the PR itself (title, etc)
* `compilation` runs on a Mac after running unit tests for your iOS app and comments about warnings, test failures, etc
* `uitests` runs on a Mac after running UI Unit tests and comments about test failures

``` sh
bundle exec danger --danger_id=unit_tests
```

#### I want to always create a new Danger comment instead of editing an existing one

You can use `--new-comment` to do this

```
bundle exec danger --new-comment
```

#### Danger isn't working on OSS forks (or "you should stop recommending people use open tokens")

If you have Danger running on a OSS project, you should be using a token that is publicly available on CI or 
external contributors cannot have danger rules applied. 

You work around this security hole by making the bot [have no access to any repos](https://danger.systems/guides/getting_started.html#creating-a-bot-account-for-danger-to-use). Meaning that the only
thing the bot can do is comment on OSS projects.

If you *need* to give the access to your bot to particular private repos or rights to certain resources, then you
can only make Danger run on branches. These are logical rules for safety by CIs with env vars I'm afraid.

If this is a blocker, there's [always Peril](https://github.com/danger/peril).

#### I use a Build Matrix on Travis, can I run Danger once?

Yep, here is an example of moving to support that from [the Ruby Grape project](https://github.com/ruby-grape/grape/pull/1458).

#### Danger keeps getting referred to as "her/she", what gives?

When we were in the naming process of Danger, we went through a lot of names. In the end, it got named after Gem "Danger" McShane, who was involved in both the copy and the concept. While not a programmer herself, she's helped out with trying to understand the personality behind the project. Danger, the project, is a female, northern UK, command-line app into 80's punk/indie. Inspired by community efforts [like the Haçienda / Factory Records][hacienda].

<iframe src="https://embed.spotify.com/?uri=spotify%3Auser%3Aortatherox%3Aplaylist%3A39vTSdxtIKzpEybyvTs3Ll" width="300" height="380" frameborder="0" allowtransparency="true"></iframe>

Understandably, applying a gender to a genderless concept comes with it's own complications. To make it worse, female genders tend to be applied towards "[digital assistants][assistants]" which should raise questions on outdated-but-still-persisting gender stereotypes and patriarchical power structures. There is no answer that can completely absolve the disconnect I'm afraid.

[hacienda]: http://www.prideofmanchester.com/music/hacienda.htm
[assistants]: http://www.theatlantic.com/technology/archive/2016/03/why-do-so-many-digital-assistants-have-feminine-names/475884/

#### Danger is not posting to GitHub PRs, but everything looks fine?

Try logging in to your account that is writing the messages, it's possible that your account has triggered the bot detection algorithm on GitHub. This means that messages are sent correctly, but do not show up for anyone except the sender. This makes it more or less impossible to detect.

#### Why am I seeing "set Status Failed" on my GitHub OSS project

Because we recommend not adding your bot to your OSS project, Danger will not be able to post status updates on a PR. A status update is the green/red/yellow dots at the end of your PR page. This does not affect Danger's ability to comment, and fail your CI build, so you are fine to ignore the message. 
