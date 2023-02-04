# [Choice] Ruby version (use -bullseye variants on local arm64/Apple Silicon): 3, 3.1, 3.0, 2, 2.7, 2.6, 3-bullseye, 3.1-bullseye, 3.0-bullseye, 2-bullseye, 2.7-bullseye, 2.6-bullseye, 3-buster, 3.1-buster, 3.0-buster, 2-buster, 2.7-buster, 2.6-buster
ARG VARIANT=3.1-bullseye
ARG USERNAME=postgres
ARG USER_UID=1002

FROM mcr.microsoft.com/vscode/devcontainers/ruby:0-${VARIANT}

RUN useradd -ou 0 -g 0 postgres \
    && apt-get update \
    && apt-get install -y sudo \
    && echo postgres ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/postgres \
    && chmod 0440 /etc/sudoers.d/postgres

COPY .pgpass /vscode/.pgpass

RUN gem install rails webdrivers 

#vglist dependencies
RUN gem install bundler:2.3.3
RUN apt update
RUN apt install -y imagemagick

# Default value to allow debug server to serve content over GitHub Codespace's port forwarding service
# The value is a comma-separated list of allowed domains 
ENV RAILS_DEVELOPMENT_HOSTS=".githubpreview.dev"
ENV VGLIST_DATABASE_PASSWORD="postgres"
ENV VGLIST_DATABASE_USERNAME="postgres"
# [Choice] Node.js version: lts/*, 16, 14, 12, 10
ARG NODE_VERSION="lts/*"
RUN su vscode -c "source /usr/local/share/nvm/nvm.sh && nvm install ${NODE_VERSION} 2>&1"

# [Optional] Uncomment this section to install additional OS packages.
# RUN apt-get update && export DEBIAN_FRONTEND=noninteractive \
#     && apt-get -y install --no-install-recommends <your-package-list-here>

# [Optional] Uncomment this line to install additional gems.
# RUN gem install <your-gem-names-here>

# [Optional] Uncomment this line to install global node packages.
# RUN su vscode -c "source /usr/local/share/nvm/nvm.sh && npm install -g <your-package-here>" 2>&1
