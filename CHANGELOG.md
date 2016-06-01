## Master

* Support multiple Danger instances with `--dangerId` - marcelofabri
* Add base request source so services other than GitHub could be used with Danger. - justMaku

## 0.8.1

* Fix Ruby 2.0 support - segiddins

## 0.8.0

* Considerable under-the-hood changes around the DSL, shouldn't affect end-user Dangerfiles though - orta
* Fix for `danger local` crash due to ^ - dbgrandi
* Add support for Drone CI - gabro
* [BREAKING] Add initial support for more expressive and documented plugins. Breaks all existing plugins. - dbgrandi/orta
* All core DSL attributes are handled via Danger Plugins - orta
* Initial work on the Plugin -> JSON mapper - orta
* Add support for Semaphore CI - starsirius
* Add Ruby 2.3 support - segiddins
* Allow Dangerfile path to be configured - gabro

## 0.7.4

* Adds the ability to specify a PR number in `danger local` - orta
* Ensures local branches are set up with  `danger local` - orta
* Add `commits` for the Git SCM source - segiddins

## 0.7.3

* Minor `danger init` typo fixes - orta + danger
* Added support for CLAide-based plugins - segiddins

## 0.7.2

* Auto follow of remote plugin URL redirects - KrauseFx
* Adding XcodeServer provider - antondomashnev

## 0.7.1

* Hotfix: import of plugins didn't work depending on alphabetical order - KrauseFx

## 0.7.0

* Added support for local plugins - KrauseFx
* Added support for remote plugins - KrauseFx
* Added new `danger new_plugin` command to create plugins in the fastlane - KrauseFx
* Added printing of table summaries after running danger - KrauseFx
* Refactored all plugins to be classes instead of methods - KrauseFx
* Added auto-import of local plugins - KrauseFx
* Resolved issues are now crossed out by Danger - marcelofabri
* Added new `markdown` command to Danger DSL - KrauseFx
* Added new `modified_files.include?("rakelib/*_stats.rake")` file globbing support - KrauseFx

## 0.6.5

* Enterprise GitHub support - dbgrandi
* Use branches for comparison, not commits - orta
* Breaking: DSL change `files_*` to `*_files` for readability - jeroenvisser101

## 0.6.0

* Added internal plugin system - KrauseFx
* Refactored unit tests - KrauseFx
* Fixed issue when PR Title or PR body is nil - KrauseFx
* Added support for `git://`-prefixed url as remote - jeroenvisser101
* Added comment based violation suppression - marcelofabri

## 0.5.2

* Typo fixes for `danger init` - lumaxis

## 0.5.1

* Fixes for `danger init` - krausefx

## 0.5.0

* New: Converted `danger init` into a wizard for setting up Danger, walking you though tokens/ci - orta
* Breaking: `files_removed` to `files_deleted` ( to be more consistent with git's terminology. ) - orta

* Revised underlying git tooling for generating file/diff metadata - orta
* re-revise underlying git tooling to not use something based on libgit2 - orta
* Set CHANGELOG merge strategy to union - marcelofabri
* Remove `nap` dependency - marcelofabri
* Show command summary in help - marcelofabri
* Use 100% width tables for messages - marcelofabri

## 0.3.0

* Adding Jenkins provider - marcelofabri
* Add a `danger local` command to test your current Dangerfile against the last PR merged on the repo - orta
* Calling CircleCI API when `CI_PULL_REQUEST` is not set - marcelofabri
* Look inside PR JSON for the commit range (instead of getting from CI providers) - marcelofabri
* Adds `pr_labels` to DSL - marcelofabri
* Makes the CircleCI provider validate, but not run on non-PR builds - orta
* Take the git before...after references out of ENV vars from CI providers - orta
* Fixes CircleCI when dealing with URLs like `https://github.com/artsy/eigen/compare/b0f6a2a9ff6f%5E...316b694875c8` - orta
* Ensure all comments are downloaded, previously it was capped at 30 - orta
* Attach commit metadata to the message invisibly - orta
* On danger/danger we now fail if there's no changelog entry - orta
* Moved to an org [feb 9]
* Adds support for Circle CI on danger/danger

## 0.2.1

* Edits an existing ticket rather than making a new one - orta

## 0.2

* Support making comments on a GitHub PR - Felix
* Use GitHub status API to provide extra info on a PR - Felix
* DRY the HTML comment - orta
* Don't show a message if there are not warnings/errors - orta

## 0.1

* Parses a `Dangerfile` - orta
* Gets GitHub details from Travis & CircleCI - orta
* Gets PR details from GitHub - orta
* Gets Git details from local Git - orta
* Fails when you say it's failed in  the  Dangerfile - orta
