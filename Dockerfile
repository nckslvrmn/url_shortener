FROM ruby:2.6.1

COPY Gemfile Gemfile
RUN bundle install

WORKDIR /opt/url_shortener

COPY . .

CMD puma
