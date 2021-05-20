FROM ruby:2.7.2-slim-buster

RUN apt-get update -qq && apt-get install -y build-essential
# Upgrade RubyGems and install required Bundler version
RUN gem update --system && \
    gem install bundler:2.2.16

ENV PORT=9293

ADD Gemfile Gemfile
ADD Gemfile.lock Gemfile.lock

RUN bundle install --jobs=8

COPY . .

ENTRYPOINT ["bundle", "exec"]
CMD ["thin", "start"]
