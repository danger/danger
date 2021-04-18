---
title: A Quick Ruby Overview
subtitle: Ruby
layout: guide
order: 5
---

### Aims of this Guide

My assumption is that you are a programmer, with some experience. You should be familiar with the terminal. This guide aims to cover enough Ruby for you to feel somewhat productive. You don't need to know all of the details of the language, but you should probably have some familiarity with a few of these major topics.

Ruby has a repl, the best one by far is `pry`. So, if you want to have a play with the language. Run `gem install pry` then run `pry`. If the gem does not install, you should follow [the instructions here](https://guides.cocoapods.org/using/getting-started.html#sudo-less-installation) to do a sudo-less install.

### Environment

The `Dangerfile` is a scripting environment, this means that you can totally get by with some simple hacking. Inside the Dangerfile, you only need to understand how to manipulate the data exposed via the API. You can see the full extent of the DSL in [the reference](/reference.html) and from the plugins overview in the [homepage](/).

Realistically, the DSL is small. To be productive in your `Dangerfile` you will need to use Ruby to put the pieces together. You don't need to be a pro at Ruby though, as you'll mostly be doing string and array manipulation, file accessing, and executing shell commands. Which is what we'll cover here.

### Variables and Keyword Syntax

Ruby does not have a keyword for variables, so you can write `path = "./the/path"` and you can re-use it later on.

For methods, parentheses are optional. You can write `do_something` and `do_something()`. Method parameters are fine with this too: `do_something "OK", 3`. Danger tries to use named parameters a lot, so you might end up writing `do_something "OK", times: 3`.

If statements are cool in Ruby, here's some interesting cases:

Plain old if statement:
```ruby
if three == 3
  do_something
end
```

For single actions, you can move it before the `if`, this is succinct, and matches how English reads:

```ruby
do_something if three == 3
```

If you need to negate something, you can use `unless` instead of a `!`:

```ruby
unless three == 3
  not_something
end
```

### Strings

You can use both double and single quotes to create a string, though single quotes don't do interpolation. This means you should nearly always use double quotes.

If a function has a `!` in it, that generally means it mutates the object. Otherwise you get a change if there's an `=` in the LOC.

```ruby
name = "orta"                 # orta
name += " therox"             # orta therox
name.start_with? "orta"       # true
name.end_with? "orta"         # false
name.gsub "orta", "Orta"      # Orta therox
name.gsub /therox/, 'Therox'  # orta Therox
# Note the !, this will mutate `name`.
name.gsub! /therox/, 'Therox' # orta Therox
name.include? "ta thero"      # false
name.include? "Thero"         # true
name[0..3]                    # orta
```

There are multiple ways to make a string, I recommend using double quotes `"` like above. If you want to do string interpolation with it, you can use `#{}` and run code inside the brackets. `"5 = ${ 2+3 }"`.

That should be enough to play around with your code review data.

### Arrays and Closures

Arrays are also mostly immutable, it's common to iterate with `array.each` instead of `for thing in array`. Closures for functions like `each`, `map`, `select`, `flat_map`, `reject` and the like, can be executed with a single line with braces:

``` ruby
paths.map { |path| File.read(path) }.select { |content| content.include? "orta" }
```

For longer closures, it's common to use `do` and `end`:

```ruby
paths.each do |path|
  path.name += "Dangerfile"
  do_something path
end
```

Finally, the simplest "closure", that only works if you want to call a function on the object in your collection is this interesting pattern: `lowercase_path = paths.map(&:downcase)` - where `downcase` is a function on the strings in the array.

`Note:` In Danger, for lists of files (e.g.`git.modified_files`) we use a class called a `FileList` which is an array subclass. [This adds one extra method](https://github.com/danger/danger/blob/master/spec/lib/danger/core_ext/file_list_spec.rb): `include?`. This lets you use [path globbing](http://wiki.bash-hackers.org/syntax/expansion/globs) to determine if a string is in the list:

```ruby
paths = ["path1/file_name.txt", "path1/file_name1.txt", "path2/subfolder/example.json"]
filelist = Danger::FileList.new(paths)

filelist.include? "path1/file_name.txt"   # true
filelist.include? "path2/*.json"          # true
filelist.include? "path1/*.json"          # false
```

### Files

You can read a file with `File.read("path/to/file")` this returns a string, or nil. Paths within Danger are represented as strings.


### Terminal commands

There are three ways to interact with commands to do something.

The humble backtick ` - Takes whatever shell command you want to run, and returns a string of the output, and a final newline. You don't see any output by default.

```ruby
plugin_json = `bundle exec danger plugin json`
```

`system` - Outputs the command you run in the shell, it will return `true` if the process succeeded.

```ruby
send_congrats if system("gem install pry")
```

`exec` - Replaces the current process with another, you probably won't be needing this for Danger.

If you want to know more about any of these, check out [this Stack Overflow](http://stackoverflow.com/questions/6338908/ruby-difference-between-exec-system-and-x-or-backticks).

### JSON Parsing

To work with JSON data, you _may_ have to `require` the JSON library first. Note some systems are case-sensitive, so always do `require "json"`. I keep getting this wrong, it's always in lowercase. :D

For example grabbing some JSON data, parsing it, then pulling something out:

```ruby
path = "path/to/file.json"
contents = File.read path

require "json"
json = JSON.parse contents

thing = json["things"][0]
```

###  Running a Dangerfile inside IRB

There's a [great section in the troubleshooting](/guides/troubleshooting.html#i-want-to-be-a-danger-wizard) on letting you dig around inside Danger via `pry`.
