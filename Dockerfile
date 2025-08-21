FROM ruby:3.4-alpine

## Install build dependencies
RUN apk add --no-cache build-base libxml2-dev libxslt-dev sqlite-libs sqlite-dev yaml-dev jemalloc

## Use jemalloc as malloc replacement
ENV LD_PRELOAD=/usr/lib/libjemalloc.so.2

RUN bundle config build.nokogiri --use-system-libraries

ENV APP_HOME /blinq/
RUN mkdir -p $APP_HOME
WORKDIR $APP_HOME

COPY Gemfile Gemfile.lock $APP_HOME

RUN gem install bundler && bundle install --jobs 20 --retry 5

COPY . $APP_HOME

EXPOSE 3000

CMD [ "bundle", "exec", "puma", "-C", "config/puma.rb" ]
