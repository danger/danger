---
title: What does Danger do?
subtitle: Danger wot
layout: guide
order: 3
---

Danger makes it easy to create feedback loops in code reviews through automation. This makes it possible to move cultural norms within your team into code, as well as easily share them with the world.

To pull that off, Danger needs to be able to run inside your continuous integration (CI) environment, and to be able to provide feedback to your code review platform. This document describes what happens when you run `bundle exec danger`.

1. First she sets up the core plugins for Danger, these are the classes documented in the reference. They provide the user API for Danger.
1. Next she determines if she's running on a CI service she recognizes. She does this by [looking][bitrise_example] at the environment variables in your console.
1. After being sure about the environment, she checks if this is a code review build. For single commit / merge builds, Danger does not run.
1. With the environment set up, she generates diff information, and pulls down status information for the code review.
1. Danger then runs your local `Dangerfile`.
1. After parsing the local `Dangerfile`, she then checks for an [organization][multi_repos] `Dangerfile` and runs that if it exists.
1. Danger then posts a comment into your code review page showing the results of the `Dangerfile`s.
1. Finally Danger either fails the build, or exits with a successful exit code.

### Plugins

Danger was built with a plugin structure in mind from day one. The [core of Danger itself aims to be small][vision], with space for others to easily build sharable plugins that extend Danger to fix common issues. All of the Danger API is built in plugins.

To simplify the experience for consumers of plugins, Danger does very little. Each plugin adds an instance of the plugin's class into the `Dangerfile`, plugins are then free to use their own methods and store their own data in memory. One of the up-sides of this is that if you want to take some code from your `Dangerfile`, and turn it into a plugin - it would be source-compatible.

[multi_repos]: /guides/faq.html#i-want-to-run-danger-across-multiple-repos
[vision]: https://github.com/danger/danger/blob/master/VISION.md
[bitrise_example]: https://github.com/danger/danger/blob/e98dc7156268adcd132d114d02d7935375f42452/lib/danger/ci_source/bitrise.rb