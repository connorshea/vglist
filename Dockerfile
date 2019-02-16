# Dockerfile for running the application in a production environment.
# Can be run locally for testing that matches production very closely.
FROM ruby:2.6.1-alpine3.9

ENV APP_ROOT continuefromcheckpoint
ENV BUNDLER_VERSION 2.0.1
ENV RAILS_ENV production
ENV RACK_ENV production
ENV NODE_ENV production
ENV RAILS_SERVE_STATIC_FILES true
ENV RAILS_LOG_TO_STDOUT true
# TODO: Fix this, it'll bite you in the ass if you don't fix it before
# deploying to production.
# Stupid workaround for https://github.com/rails/rails/issues/32947
# Maybe move SECRET_KEY_BASE to be included in credentials.yml.enc?
ENV SECRET_KEY_BASE=dumb

RUN apk add --no-cache --update build-base \
                                linux-headers \
                                git \
                                postgresql-dev \
                                nodejs \
                                yarn \
                                bash \
                                tzdata \
                                imagemagick

RUN mkdir /$APP_ROOT
WORKDIR /$APP_ROOT
COPY Gemfile /$APP_ROOT/Gemfile
COPY Gemfile.lock /$APP_ROOT/Gemfile.lock
# Install the right version of Bundler.
RUN gem install bundler:$BUNDLER_VERSION
RUN bundle install --jobs=4 --without "test development"
# Copy package.json and yarn.lock, then install yarn packages.
COPY package.json /$APP_ROOT/package.json
COPY yarn.lock /$APP_ROOT/yarn.lock
RUN yarn install --frozen-lockfile

# Copy the rest of the files. We do this last to speed up regeneration of the Docker image.
COPY . /$APP_ROOT

# Pre-compile webpack packs.
RUN bundle exec rails assets:precompile

# Start the main process.
CMD ["rails", "server", "-b", "0.0.0.0"]
