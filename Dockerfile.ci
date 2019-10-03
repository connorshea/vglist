# Dockerfile for running the application in a CI environment.
FROM ruby:2.6.5

RUN curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add -
RUN curl -sL https://deb.nodesource.com/setup_10.x | bash -
RUN echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list
RUN curl -sSL https://dl.google.com/linux/linux_signing_key.pub | apt-key add - && echo "deb https://dl.google.com/linux/chrome/deb/ stable main" > /etc/apt/sources.list.d/google-chrome.list
RUN apt-get update -qqy && apt-get install -qqyy google-chrome-stable yarn nodejs postgresql postgresql-client
