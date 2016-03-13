## Master

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
