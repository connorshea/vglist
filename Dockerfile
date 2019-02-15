# Dockerfile for running the application in a production environment.
# Can be run locally for testing that matches production very closely.
FROM ruby:2.6.1

ENV APP_ROOT continuefromcheckpoint
ENV BUNDLER_VERSION 2.0.1
ENV RAILS_ENV production
ENV RACK_ENV production
ENV NODE_ENV production
ENV RAILS_SERVE_STATIC_FILES true
ENV RAILS_LOG_TO_STDOUT true
# Stupid workaround for https://github.com/rails/rails/issues/32947
# Maybe move SECRET_KEY_BASE to be included in credentials.yml.enc?
ENV SECRET_KEY_BASE=dumb

RUN apt-get update -qq

# Install Yarn and Node 10
# https://github.com/nodesource/distributions/blob/d2071b9ddda150371c59db9a40a19b02666358b2/README.md#installation-instructions
RUN curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add -
RUN curl -sL https://deb.nodesource.com/setup_10.x | bash -
RUN apt-get install -y nodejs
RUN echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list

RUN apt-get update -qq && apt-get install -y postgresql-client yarn
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
