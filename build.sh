gem install bundler
bundle exec rake spec

if [-z "$SURF_BUILD_NAME" ]; then
	## Posting to GitHub
	bundle exec danger
else
	## Local clean build, just print to console
	bundle exec danger local
fi
