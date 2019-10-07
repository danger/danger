FROM ruby:2.5

RUN apt-get update -qq && apt-get install -y build-essential p7zip unzip

ENV APP_HOME /myapp
RUN mkdir $APP_HOME
WORKDIR $APP_HOME

COPY ./Gemfile $APP_HOME
COPY ./Gemfile.lock $APP_HOME

RUN bundle install

COPY . $APP_HOME

CMD bundle exec danger pr
