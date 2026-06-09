FROM ruby:3.2 AS builder

RUN apt-get update -qq && \
    apt-get install -y --no-install-recommends build-essential && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /myapp
COPY . /myapp

ENV BUNDLE_WITHOUT="development:test"
RUN gem install bundler && bundle install

FROM ruby:3.2-slim

LABEL "com.github.actions.name"="Danger"
LABEL "com.github.actions.description"="Runs danger in a docker container such as GitHub Actions"
LABEL "com.github.actions.icon"="mic"
LABEL "com.github.actions.color"="purple"
LABEL "repository"="https://github.com/danger/danger"
LABEL "homepage"="https://github.com/danger/danger"
LABEL "maintainer"="Rishabh Tayal <rtayal11@gmail.com>"
LABEL "maintainer"="Orta Therox"

RUN apt-get update -qq && \
    apt-get install -y --no-install-recommends git p7zip-full unzip && \
    rm -rf /var/lib/apt/lists/*

# See https://github.com/actions/runner/issues/2033
RUN git config --system --add safe.directory /github/workspace

WORKDIR /myapp
COPY --from=builder /usr/local/bundle /usr/local/bundle
COPY --from=builder /myapp /myapp

ENV BUNDLE_GEMFILE=/myapp/Gemfile
ENV BUNDLE_WITHOUT="development:test"
ENTRYPOINT ["bundle", "exec", "danger"]
