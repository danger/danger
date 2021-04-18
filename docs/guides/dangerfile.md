---
title: The Dangerfile
subtitle: The Dangerfile
layout: guide
order: 2
---

A `Dangerfile` is a [Ruby DSL][dsl]. Before the ruby code inside your `Dangerfile` is executed, she grabs useful bits of data about: the CI environment, the git diff, and the code review details. There is a full writeup of what happens in ["What does Danger do?"][wot_do]. For now that's enough.

The `Dangerfile` is where you create your rules, Danger comes with no rules set up by default. This is on purpose, we don't know your culture.

We've found it easier to start with something as simple as 

```ruby
if github.pr_body.length < 5
  fail "Please provide a summary in the Pull Request description"
end
```

Which is a pretty safe bet. Then over time, when your team notices that something can be easily automated, you add it as another rule. Bit by bit.

Where to go from here:
- [Working locally on your `Dangerfile`][troubleshooting]

[wot_do]: /guides/what_does_danger_do.html
[dsl]: https://www.infoq.com/news/2007/06/dsl-or-not
[troubleshooting]: /guides/troubleshooting.html#i-want-to-work-locally-on-my-dangerfile
