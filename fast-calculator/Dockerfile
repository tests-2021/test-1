FROM ruby:3.0.0

# Common dependencies
RUN apt-get update -qq \
  && DEBIAN_FRONTEND=noninteractive apt-get install -yq --no-install-recommends \
    build-essential \
    gnupg2 \
    curl \
    less \
    git \
    cmake \
    pkg-config \
    vim \
    libxml2-dev \
    libxslt-dev \
    nodejs \
    npm \
    yarn \
  && rm -rf /var/cache/apt/archives/* \
  && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* \
  && truncate -s 0 /var/log/*log

# Application dependencies
RUN apt-get update -qq && DEBIAN_FRONTEND=noninteractive apt-get -yq dist-upgrade && \
  DEBIAN_FRONTEND=noninteractive apt-get install -yq --no-install-recommends \
    libpq-dev && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* && \
    truncate -s 0 /var/log/*log

# Upgrade RubyGems and install required Bundler version
RUN gem update --system && \
    gem install bundler:2.2.16

# Create a directory for the app code
RUN mkdir -p /app
WORKDIR /app

COPY ./Gemfile /app
RUN bundle lock --add-platform x86_64-linux
RUN bundle install

RUN echo "Node: " && node -v
RUN echo "NPM: " && npm -v
COPY ./ /app
RUN npm install -g yarn
RUN yarn install

