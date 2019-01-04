FROM ruby:2.5

LABEL "com.github.actions.name"="Danger"
LABEL "com.github.actions.description"="Runs danger in a docker container such as Github Actions"
LABEL "com.github.actions.icon"="mic"
LABEL "com.github.actions.color"="purple"

LABEL "repository"="http://github.com/danger/danger"
LABEL "homepage"="http://github.com/danger/danger"
LABEL "maintainer"="Rishabh Tayal <rtayal11@gmail.com>"

RUN apt-get update -qq && apt-get install -y build-essential p7zip unzip

ENV APP_HOME /myapp
RUN mkdir $APP_HOME
WORKDIR $APP_HOME

ADD ./Gemfile $APP_HOME/Gemfile
ADD Gemfile.lock $APP_HOME/Gemfile.lock

RUN bundle install

COPY . $APP_HOME

CMD bundle exec danger pr
