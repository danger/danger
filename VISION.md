### The Danger Vision

Danger is a long-term project. From our current viewpoint, her role is:

 * An automated reviewer of your code.

Though we initially envisioned that Danger would provide an API for looking at file diffs in Git, real-life usage showed that it was far more useful to provide workable automated feedback on pull requests.

### How She Does It

Danger's core concept is a system that is easy to build upon. The codebase for Danger should resolve specifically around systems for CI (e.g. Travis), communication with Peer Review tools (e.g. GitHub), and providing APIs to Source Control changes (e.g., Git).

These abstractions enable an individual to think about writing a `Dangerfile` as its own DSL subset of the Ruby programming language. This means that decisions on new code integrated into Danger should ask "is this valid for every CI provider, every review system, and every source control type?" By making this domain so big, we can keep the core of Danger small.

### General Aim

Danger should provide a small core, but be as open as possible for others to build upon. This affords two major advantages: Danger's maintainers can spend their time on the kernel of Danger, while others have first-party access to create tools that the maintainers could never have conceived of. By being conservative for the core, we can provide a solid, dependable framework to work from.

We want to provide different tools for people to build on Danger via plugins. A plugin can be a gem installed via rubygems or bundler, wherein it will be considered part of the community of Danger plugins. Or, it can be a single Ruby file that can be accessed via https or Git, which make great one-off projects.

### Plugins

We should aim to be as explicit as possible in the Danger Plugin contract, such that it is possible to centralise the infrastructure. It would be a shame to have many people work on the same project without knowing they're duplicating each other's work. By enforcing standards via the core, such as "always use a `danger-` prefix on your gem" and "always use rubydoc for code comments", we can build a central search and documentation engine to lower the barriers for consumers to use and share plugins. This technique is used in CocoaPods to ensure [reference material](https://github.com/CocoaPods/guides.cocoapods.org/blob/master/lib/doc/generators.rb#L1) is always up-to-date with [the code](https://github.com/CocoaPods/Core/blob/master/lib/cocoapods-core/podfile/dsl.rb).

At the moment, a plugin is comprised of: DSL attributes and plugin-commands.

* **DSL Attributes** - These are ways in which explicit free-form functions can be added to the `Dangerfile` that have specific domain knowledge, but that may not be applicable in every case of using the plugin.

* **Plugins Command** - These are ways in which you can provide implicit checks that happen when a plugin is activated in a `Dangerfile`.

For example, consider a Danger plugin for blogging with [Jekyll](http://jekyllrb.com). You may make checking for 404s on external links a plugin command, as it's applicable everywhere, but make grammar checking on Markdown files a DSL attribute because not everyone would want it.

### Communication

So far, a lot of discussion about Danger happens within GitHub issues. Ideally, we will keep it that way until Danger becomes big enough that this is a problem. The advantages of this is that all documentation and issues are publicly searchable and easily linked to the source code. Tools such as Slack and Gitter are great for building a culture, but can reduce the transparency of an organization.

One way in which we're trying to improve on this is by conforming to [Moya's Community Continuity document](https://github.com/Moya/contributors), which aims to include as many people into the process as possible. Though there are gate-keepers around shipping the gem, which is released to the public, in our experience giving everyone push access to the source code has not bitten the projects we've worked on.

With a lot of these things, though, they're about scale.

### Contributions

The Danger project should aim to devote a lot of time to making plugin contributors feel like an important part of the team. Examples of where this has worked well is the [jQuery project](https://plugins.jquery.com). We should strive to provide a place for anyone to be able to own a context for working with Danger (e.g. blogging with Jekyll). The aim of the core team should be to work on ways to showcase that to encourage adoption and show off great work. An example of where this worked is the [CocoaPods Quality Index](http://blog.cocoapods.org/CocoaPods.org-Two-point-Five/).
