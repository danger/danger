---
title: Creating your first Plugin
subtitle: Plugin creation
layout: guide
order: 4
---

So, you want to make a Danger Plugin? This is _awesome_. We all have common
issues, and this is a great way to share code with the world. We've found once a
single rule becomes longer than 10-15 lines of code, converting it into a plugin
makes a lot of sense.

The concept of a Plugin in Danger is very simple. It's a subclass of
`Danger::Plugin`.

If you don't know about Ruby modules, then don't worry, think of it as Ruby
namespacing. That's the `Danger::` bit. You'll have to create a class that is a
subclass of `Plugin` inside a `Danger` `module`.

### Tech Specs

This subclass will be created automatically with a reference to the current
`Danger::Dangerfile` ruby object. It will be created before the
`Dangerfile`([s][multiple_danger]) are parsed by it.

There are no ways to automatically execute code with knowledge of the current
status. A plugin should get told to do some work from the user's
`Dangerfile`(s).

Your plugin is added as an attribute to the user's `Dangerfile`(s), this is
based on your class name, but is editable.

```ruby
def self.instance_name
  to_s.gsub("Danger", "").danger_underscore.split("/").last
end

# e.g. removes "Danger", converts camel case to snake case, and splits if there's any /s

# DangerProse -> prose
# DangerMyThing -> my_thing
# MyPlugin -> my_plugin
``` 

#### Same Source

One of the great things about a Danger Plugin is that the code is exactly the
same as it was in your `Dangerfile`. A plugin has access to all of the same
methods and attributes as you had when it was being parsed inside a
`Dangerfile`. This is because anything your plugin doesn't understand gets
passed to the current `Dangerfile` for it to have a chance to act.

This is useful mainly in two things:

* Low barrier to entry.
* You have access to all of the other plugins.

### Creating the Plugin

Starting is pretty simple, we have a [template][template]. As well as a command
to get you started. Your first step is the name: the [Rubygems rule][gem_rules]
is `[core_app]-[gem]_[name]`. So, the first space is always a `-` then later
spaces would be `_`. E.g. `danger-wizard_hat`.

Now that you know the rules, in your development folder run `danger plugins
create [name]`. This will create a README similar to the one for
[danger-proselint][prose_readme].

```
$ danger plugins create guitar_lessons

-> Creating `danger-guitar_lessons` plugin

[!] using template 'https://github.com/danger/danger-plugin-template'
-> Configuring template
Configuring danger-guitar_lessons
user name:Orta Therox
user email:orta.therox@gmail.com
year:2016
```

This sets you up with this folder structure:

```
danger-guitar_lessons
├── .travis.yml
├── Gemfile
├── Guardfile
├── LICENSE.txt
├── README.md
├── Rakefile
├── danger-guitar_lessons.gemspec
├── lib
│   ├── danger_guitar_lessons.rb
│   ├── danger_plugin.rb
│   └── guitar_lessons
│       ├── gem_version.rb
│       └── plugin.rb
└─  spec
    ├── guitar_lessons_spec.rb
    └── spec_helper.rb
```

Which covers a lot of the basics for you.

#### Source

The template isn't empty, it comes as an existing simple plugin based on our
work in [danger-prose][prose]. This is to make it easier to show how all of the
plugin comes together, I'd recommend reading through these files in this order:

* `/lib/[NAME]/plugin.rb`
* `/spec/spec_helper.rb`
* `/spec/[NAME]_spec.rb`

These are main places where you would be doing work.

You'll want to move your code into the file at `/lib/[NAME]/plugin.rb`. Then you
can write some tests to ensure nothing will break in the future.

#### Tests

The template comes with some tests for the example plugin. It already comes with
infrastructure to have a `Danger::Dangerfile` instantiate your plugin. You can
start off by modifying that to work with your plugin.

To run all of the tests, you can use the command `bundle exec rake spec`. The
testing infrastructure is [RSpec][rspec], the template also comes with a
`Guardfile` for use with [guard][guard] with [guard-rspec][guard_rspec]. This
means you can run `bundle exec guard` and it will start a server which listens
for test changes and re-runs your tests as you work.

If you're new to testing on ruby, here are some examples that you can use as a
reference:

* [`danger-proselint - danger_plugin_spec.rb`][specs_prose]
* [`danger - request_source_spec.rb`][specs_danger]
* [`danger - string_spec.rb`][specs_danger_string]
* [`danger-rubocop - danger_plugin_spec.rb`][specs_rubocop]

#### CI

This template comes with a `.travis.yml` file that lints your documentation, and
offers advice on the syntax of your Ruby. If you want to quickly change the
syntax, run `bundle exec rubocop -a` in the directory.

#### Adding the Gem to your Project

To test your project back with the codebase you've extracted the code from,
you'll need to use a `Gemfile`. So many `Thingfile`s, right?

You should add a `gem` using the `:path` attribute. e.g. add a new line with:

``` ruby
gem "danger-guitar_lessons", :path => "../danger-guitar_lessons"
```

Then when you run `bundle install` your new gem is added to the project. You can
then use `bundle exec danger local` to test inside you project. You can make
changes to your plugin, then you only need to run `bundle exec danger local`.

### Automate your README

Danger can generate your README based on the inline documentation in your
plugin. To do this, run `bundle exec danger plugins readme`. The markdown will
be output into your terminal, then you can copy & paste it into `README.md`.

### Pushing to RubyGems

So you're ready to ship now, you've got a few tests, and you've ran it inside
your project using a `:path` `gem`.

You're going to want to push it to [RubyGems][rubygems], here's their guide on
[publishing a gem][rubygems_publish].

Once it's on RubyGems, then you should change your application's Gemfile to
remove the `:path` and let it become the public gem. Awesome. That's you ready
for using your plugin in production.

### Getting it on Danger.Systems

Having a plugin available on RubyGems means anyone can use it.

This is entirely optional, however having your gem on this site means that it
will be more visible!

In order to go on Danger.Systems you need to ensure the running `bundle exec
danger plugins lint` passes.

This means that the plugin is well documented so that the site can generate a
page for it. The linter will guide you through the process, and show you
examples of how to use the documentation syntax.

Once you are all green, and ideally warning free in the linter. You should send
a merge request to [danger.systems/plugins.json][plugins_json]. Please don't add
it as the first item.

### Extra Credit

If you want to make sure that your plugin's docs are always up to date, you can follow
the [instructions here](https://gitlab.com/danger-systems/danger.systems#danger-systems-webhookherokuappcom-1)
to set up a webhook which triggers this static site to update and with latest release. 

### Supporting multiple platforms: E.g. GitHub, GitLab, etc

You can determine if another plugin exists (all Platforms are plugins) but doing `defined? @dangerfile.[plugin_name]`

Here is an example of GitLab and GitHub support in the same plugin: [danger-mentions][mentions].

#### 10/10 WOULD PLUGIN AGAIN

[multiple_danger]: /guides/faq.html#i-want-to-run-danger-across-multiple-repos
[template]: https://github.com/danger/danger-plugin-template
[gem_rules]: http://guides.rubygems.org/name-your-gem/
[prose]: https://github.com/dbgrandi/danger-prose/
[rspec]: http://rspec.info
[guard]: http://guardgem.org
[guard_rspec]: https://github.com/guard/guard-rspec
[specs_prose]: https://github.com/dbgrandi/danger-prose/blob/cc2c618abafc9e9435a783ffa0ebca5beef4f897/spec/danger_plugin_spec.rb
[specs_danger]: https://github.com/danger/danger/blob/6daa85167efff1659bbee895b3e9a9fba0b1c9ec/spec/lib/danger/request_sources/request_source_spec.rb
[specs_danger_string]: https://github.com/danger/danger/blob/master/spec/lib/danger/core_ext/string_spec.rb
[specs_rubocop]: https://github.com/ashfurrow/danger-rubocop/blob/bef4a28b4d542810a1aeb0d7460a80a8ab842492/spec/danger_plugin_spec.rb
[rubygems]: https://rubygems.org
[rubygems_publish]: http://guides.rubygems.org/publishing/#publishing-to-rubygemsorg
[plugins_json]: https://gitlab.com/danger-systems/danger.systems/blob/master/plugins.json
[prose_readme]: https://github.com/dbgrandi/danger-prose/tree/d80e1b54a6df859c624015895f4d5d79fd11a276
[mentions]: https://github.com/danger/danger-mention/blob/dea0664085d78c3fc0e94d471519c492790b49a3/lib/danger_plugin.rb#L80-L89
