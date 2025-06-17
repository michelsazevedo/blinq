FROM ruby:3.4-alpine

RUN apk add --no-cache build-base libxml2-dev libxslt-dev
RUN apk add --no-cache sqlite-libs sqlite-dev yaml-dev

RUN bundle config build.nokogiri --use-system-libraries

ENV APP_HOME /blend/
RUN mkdir -p $APP_HOME
WORKDIR $APP_HOME

COPY Gemfile Gemfile.lock $APP_HOME

RUN gem install bundler && bundle install --jobs 20 --retry 5

COPY . $APP_HOME

EXPOSE 3000

CMD [ "bundle", "exec", "puma", "-C", "config/puma.rb" ]
