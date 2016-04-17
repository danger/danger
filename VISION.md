### The Danger Vision

Danger is a long term project, from our current viewpoint her role is

 * Provide the best API for communication in Continuous Integration.

 While we initially envisioned that she would work best at providing an API for looking at file differents in `git` - real life usage showed that the domain for easily providing workable automated feedback was far more useful than "did file x change."

### How She Does This

The core concept is that the Danger project itself creates a system that is extremely easy to build upon. The codebase for Danger should resolve specifically around systems for CI, communication with Peer Review tools and providing APIs to Source Control changes. For example: `Travis CI` - `GitHub` - `git`.

These abstractions allow an individual to think about writing a `Dangerfile` as it's own DSL sub-set of the ruby programming langauge.

This means that decisions on new code integrated into Danger should ask "is this valid for every CI provider, every review system and source control type?" by making this domain so big, we can keep the core of Danger small.

### General Aim

Danger should provide a small core, but be as open as possible for others to build upon. This means two major advantages; Danger's maintainers can spend their time on the kernel of Danger, others will have first party access to build tools that the maintainers could never have concieved of.  By being conservative for the core, we can provide a solid, dependenable framework to work from.

We want to provide different tools for people to build on Danger via plugins. A plugin can be a gem installed via rubygems or bundler. Or it can be a single ruby file which can be accessed via http or git. We should aim to be as explicit as possible in the Danger Plugin contract, so that it is possible to centralise as much as possible the infrastructure. It would be a shame to have many people working on the same projects without knowing they're duplicating each other's work.

At the moment, a plugin is comprised of: DSL attributes and plugin-commands.

* **DSL Attributes** - These are ways in which free-form functions can be added to the `Dangerfile` that can have a very specific domain knowledge, but that may not be applicable in every case of using the plugin.

* **Plugins Command** - These are ways in which you can provide implicit checks that happen when a plugin is triggered.

For example, if you had a Danger plugin around blogging with Jekyll. You may make checking for 404s on  external links a plugin command, as it's applicable everywhere, but make grammar checking on markdown files a DSL attribute because not everyone would want it.

### Communication

So far, a lot of discussion for Danger happens within GitHub issues, and ideally we should strive to keep it that way until Danger becomes big enough that this is a problem. The advantages of this is that all documentation / issues are publicly searchable, and easily linked to source. Tools like Slack and Gitter are great for culture building, but can reduce the transparency of an organization.

One way in which we're trying to improve on this is by conforming to the Moya Contbutor's agrrement about including as many people into the process as possible. While there are definitely gate-keepers around shipping the gem, which goes to the public, giving anyone push access to the source code historically hasn't bitten projects we'e worked on.

With a lot of these things though, they're about scale.

### Contrbutions

The Danger project should aim to devote a lot of time to making plugin contributors feel like an important part of the team. Examples of where this has worked well is the jQuery project. We should strive to provide a place for anyone to be able to own a context for working with Danger ( e.g. blogging wth Jekyll ) and the aim of the core team should be to work on ways to showcase that to encourage adoption and show ff great work. An example of where this worked is the CocoaPods Quality Index.
