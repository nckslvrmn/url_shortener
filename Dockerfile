FROM ruby:2.5.1-slim

RUN apt-get update -qq && apt-get install -y build-essential

COPY Gemfile Gemfile
RUN bundle install

WORKDIR /opt/url_shortner

COPY . .

CMD bundle exec puma -C puma.rb
