FROM ruby:alpine

RUN apk add build-base

COPY Gemfile Gemfile
RUN bundle install

WORKDIR /opt/url_shortener

COPY . .

CMD puma
