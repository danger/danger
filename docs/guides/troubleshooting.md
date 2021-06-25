---
title: Troubleshooting
subtitle: all broken
layout: guide
order: 7
---

### I want to work locally on my Dangerfile

There are two ways to work locally:

* I have a GitHub PR in mind: `bundle exec danger pr https://github.com/danger/danger/pull/662`
* I want to use the last merged PR in my current branch: `bundle exec danger local`

This will run the Danger environment locally, making it possible to iterate and verify syntax etc.

For closed source projects, make sure to setup the `DANGER_GITHUB_API_TOKEN` environment variable before attempting to run `local`.  If you are trying to access an Enterprise Github instance, `DANGER_GITHUB_HOST` and `DANGER_GITHUB_API_HOST` must be set.

For extra debugging powers, append `--pry` to the end of your command and you'll get put into a REPL. Then you can be a [Danger Wizard](#i-want-to-be-a-danger-wizard).


### I want to only run Danger for internal branches

Let's say you run Danger on the same CI service that deploys your code. If that's open source, you don't want to be letting a fork pull out your private env vars. The work around for this is to not simply call Danger on every test run:

``` sh
'[ ! -z $DANGER_GITHUB_API_TOKEN ] && bundle exec danger || echo "Skipping Danger for External Contributor"'
```  

This ensures that Danger only runs when you have the environment variables for her to use.

### My CI uses Ruby 1.9.x by default, and I'm not a Ruby project

Worry not. Most CIs come with either [rvm][rvm] or [rbenv][rbenv] which support multiple versions of Ruby. You can use that to change the Ruby version before running Danger.

If you're not a Ruby project, you might want to also [skip the Gemfile][skip_gemfile].

### I want to be a Danger Wizard

![](http://i.imgur.com/QCwKwKQ.gif)

Alright, alright. So the real key to working locally, is `bundle exec danger local --pry`.

Here's some tips for using pry inside Danger. You will start off running the REPL _inside_ the `Dangerfile`.

[Pry is special][pry] because it provides a UNIX folder-like structure for your object graph. You can use `ls` to see all the local variables, and attributes for your current `Dangerfile`. Then use `cd` to change the state to another object, and `cd ..` to go back.

Inside the `Dangerfile`, plugin instances are not in the default list alas, but you can get them all with `@plugins.keys.map(&:instance_name)`.

For example, to look around inside your `git` state, do a `cd git` and do `ls` again. If you want an in-depth overview of the current object use `inspect`.

To check all your warnings, errors, markdowns and messages - `cd` into the `messaging` plugin, then run `status_report` to see what has happened.

If you're interested in understand pry more, I strongly recommend digging into [their docs][pry].

### Circle CI doesn't run my build consistently

Yeah... We're struggling with that one. It's something we keep taking stabs at improving, so [keep an eye on the issues][circle_issues]. Ideally this issue will get resolved and we'll get it [fixed for free][circle_pr].


[circle_issues]: https://github.com/danger/danger/search?q=circle&state=open&type=Issues&utf8=✓
[circle_pr]: https://discuss.circleci.com/t/pull-requests-not-triggering-build/1213
[pry]: http://pry.github.io
[rvm]: http://rvm.io
[rbenv]: https://github.com/rbenv/rbenv
[skip_gemfile]: /guides/getting_started.html#installation-without-bundler
