FROM ruby:2.5

MAINTAINER Orta Therox

LABEL "com.github.actions.name"="Danger" 
LABEL "com.github.actions.description"="Runs danger in a docker container such as GitHub Actions"
LABEL "com.github.actions.icon"="mic"
LABEL "com.github.actions.color"="purple"
LABEL "repository"="https://github.com/danger/danger"
LABEL "homepage"="https://github.com/danger/danger"
LABEL "maintainer"="Rishabh Tayal <rtayal11@gmail.com>"

RUN apt-get update -qq && apt-get install -y build-essential p7zip unzip

RUN mkdir /myapp
WORKDIR /myapp
COPY . /myapp

RUN gem install bundler

ENV BUNDLE_GEMFILE=/myapp/Gemfile
RUN bundle install
ENTRYPOINT ["bundle", "exec", "danger"]
