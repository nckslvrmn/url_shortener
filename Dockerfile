FROM ruby:latest

COPY Gemfile Gemfile
RUN bundle install

WORKDIR /opt/url_shortner

COPY . .

CMD puma
