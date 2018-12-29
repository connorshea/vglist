# README

This is a Rails application for tracking your video game library.

## Getting set up

Pre-requisites:
- Ruby 2.5 or 2.6
- Postgres 10.x

Follow these instructions:

- Clone the repository with git
- If you're on Ruby 2.5, `gem install bundler` (on Ruby 2.6, bundler is included already!)
- `bundle install`
- `yarn install`
- `bundle exec db:create`
- `bundle exec db:migrate`
- `bundle exec rails s` to start the server
- Visit http://localhost:3000 in your browser and you should see the base application.
- Create a user with the "Sign up" page and then check the logs in your command line to get the confirmation link.

## Design Document

See [DESIGN_DOC.md](DESIGN_DOC.md) for the general design plan for this project.
