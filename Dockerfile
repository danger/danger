FROM ruby:2.5

LABEL "com.github.actions.name"="Danger" \
      "com.github.actions.description"="Runs danger in a docker container such as GitHub Actions" \
      "com.github.actions.icon"="mic" \
      "com.github.actions.color"="purple" \
      "repository"="https://github.com/danger/danger" \
      "homepage"="https://github.com/danger/danger" \
      "maintainer"="Rishabh Tayal <rtayal11@gmail.com>"

RUN apt-get update -qq && apt-get install -y build-essential p7zip unzip

ENV APP_HOME /myapp
RUN mkdir $APP_HOME
WORKDIR $APP_HOME

ADD ./Gemfile $APP_HOME/Gemfile
ADD ./Gemfile.lock $APP_HOME/Gemfile.lock

RUN bundle install

COPY . $APP_HOME

CMD bundle exec danger pr
