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
- Run `bundle exec rake db:seed` to seed the database with fake data (this will destroy any existing data in the database, so be careful)
  - This will create a user with the email `admin@example.com` and the password `password`, which you can use for testing purposes.
  - Alternatively, create your own user with the "Sign up" page and then check the logs in your command line to get the confirmation link.
- `bundle exec rails s` to start the server
- Visit http://localhost:3000 in your browser and you should see the base application.
- In a separate terminal window, run `ruby ./bin/webpack-dev-server` alongside the Rails server to have a webpack-dev-server instance.
  - You don't _have_ to do this for the site to work, but things will take a lot longer to load as webpack has to compile stuff from within the same process as Rails.

## Design Document

See [DESIGN_DOC.md](DESIGN_DOC.md) for the general design plan for this project.
