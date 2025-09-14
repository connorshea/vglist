# Dockerfile for running the application in a CI environment.
FROM ruby:3.4.5

RUN curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | gpg --dearmor | tee /usr/share/keyrings/yarnkey.gpg > /dev/null
RUN curl -sL https://deb.nodesource.com/setup_18.x | bash -
RUN echo "deb [signed-by=/usr/share/keyrings/yarnkey.gpg] https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list
RUN curl -sSL https://dl.google.com/linux/linux_signing_key.pub | gpg --dearmor | tee /usr/share/keyrings/chrome.gpg > /dev/null
RUN echo "deb [signed-by=/usr/share/keyrings/chrome.gpg] https://dl.google.com/linux/chrome/deb/ stable main" | tee /etc/apt/sources.list.d/google-chrome.list
RUN apt-get update -qqy && apt-get install -qqyy google-chrome-stable yarn nodejs postgresql postgresql-client
