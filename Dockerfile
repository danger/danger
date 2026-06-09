FROM ruby:3.2-alpine AS builder

RUN apk add --no-cache build-base

WORKDIR /myapp
COPY . /myapp

ENV BUNDLE_WITHOUT="development:test"
RUN gem install bundler && bundle install

FROM ruby:3.2-alpine

LABEL "com.github.actions.name"="Danger"
LABEL "com.github.actions.description"="Runs danger in a docker container such as GitHub Actions"
LABEL "com.github.actions.icon"="mic"
LABEL "com.github.actions.color"="purple"
LABEL "repository"="https://github.com/danger/danger"
LABEL "homepage"="https://github.com/danger/danger"
LABEL "maintainer"="Rishabh Tayal <rtayal11@gmail.com>"
LABEL "maintainer"="Orta Therox"

RUN apk add --no-cache git p7zip

# See https://github.com/actions/runner/issues/2033
RUN git config --system --add safe.directory /github/workspace

WORKDIR /myapp
COPY --from=builder /usr/local/bundle /usr/local/bundle
COPY --from=builder /myapp /myapp

ENV BUNDLE_GEMFILE=/myapp/Gemfile
ENV BUNDLE_WITHOUT="development:test"
ENTRYPOINT ["bundle", "exec", "danger"]
