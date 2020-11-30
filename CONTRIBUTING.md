# Contributing

## Getting set up

### Prerequisites

- Ruby 2.6
- Postgres 11.x
- Node.js 10.x
- Yarn 1.x
- ImageMagick (for images, like avatars or game covers)

### Setup instructions

1. Clone the repository with git
1. To get Bundler 2.1.4, `gem install bundler:2.1.4`
1. `bundle install`
1. `yarn install`
1. `bundle exec rails db:setup`
   - This is the equivalent of running `bundle exec rails db:create && bundle exec rails db:schema:load && bundle exec rails db:seed`, so it will create the databases, seed them with fake data, and create a user with the email `admin@example.com` and the password `password`.
   - If you would like more control, run only `bundle exec rails db:create` and `bundle exec rails db:schema:load`.
   - If you run into an error about the database password being wrong, the application will try to use `'password'` by default, but you can set the password for your database user via the `VGLIST_DATABASE_PASSWORD` environment variable.
1. `bundle exec rails server` to start the server.
1. Visit <http://localhost:3000> in your browser and you should see the base application.
1. In a separate terminal window, run `bin/webpack-dev-server` alongside the Rails server to have a webpack-dev-server instance.
   - You don't _have_ to do this for the site to work, but things will take a lot longer to load as Webpack has to compile stuff from within the same process as Rails.

#### Extras

- If you want to test the Steam import functionality, you'll need to [generate a Steam Web API Key](https://steamcommunity.com/dev/registerkey) and set it as an environment variable, `STEAM_WEB_API_KEY`.

## Libraries

This is a list of libraries used for various functionality across the app. It's not guaranteed to be comprehensive or up-to-date, but I'll try my best to keep it updated.

- [Ruby on Rails](https://rubyonrails.org): Web application framework.
  - [ActiveRecord](https://guides.rubyonrails.org/active_record_basics.html): Used for SQL queries, migrations, and maintaining the database structure.
  - [ActiveStorage](https://guides.rubyonrails.org/active_storage_overview.html): Used for image storage.
  - [Webpacker](https://github.com/rails/webpacker): JavaScript / SCSS bundler, essentially [Webpack](https://webpack.js.org) with Rails integration.
- [Sorbet](https://sorbet.org): Gradual static typing for Ruby.
- [Postgres](https://www.postgresql.org/): Database engine that the application uses.
- [PgSearch](https://github.com/Casecommons/pg_search): Powers search for games, companies, series', etc.
- [Devise](https://github.com/heartcombo/devise): Authentication framework, for logging in and other user authentication things.
- [Pundit](https://github.com/varvet/pundit): Authorization framework, used for making sure users are actually authorized to perform a given action in the application.
- [Doorkeeper](https://github.com/doorkeeper-gem/doorkeeper): OAuth authentication handler, for creating tokens used by the API.
- [RSpec](https://rspec.info/): Ruby testing framework used for unit tests, request specs, feature specs, model specs, etc.
- [FactoryBot](https://github.com/thoughtbot/factory_bot): Factories for seeding the database and writing tests.
- [GraphQL](https://graphql.org) via [graphql-ruby](https://graphql-ruby.org): GraphQL is a query language that is used for the vglist API.
- [TypeScript](https://www.typescriptlang.org): Dialect of JavaScript with static types, most of the JavaScript in the application is written in TypeScript.
- [Vue.js](https://vuejs.org): JavaScript framework for dynamic webpages, used for various complex pages and elements, e.g. the search bar, library table, etc.
- [Font Awesome](https://fontawesome.com): Icons used in the application mostly come from Font Awesome.
- [Bulma](https://bulma.io/): CSS Framework used for styling the application.

## Rake tasks

Rake tasks are Ruby code for running tasks. For vglist, most of these are for importing data.

- Importing
  - `rake import:update` - Imports updated data for existing games, companies, genres, series, etc.
  - `rake import:wikidata:games` - Imports new games.
  - `rake import:full` - Imports new games, companies, genres, series, etc.
  - `rake import:pcgamingwiki:covers` - Imports covers from PCGamingWiki.
  - `rake import:mobygames:covers` - Imports covers from MobyGames, needs a MobyGames API key.
  - `rake rebuild:multisearch:all` - Rebuild the search indices, useful after running imports.
- Deployment
  - `rake deploy:production` - Deploys the website in production mode, for use on the production server.
- Development
  - `rake sorbet:update:all` - Updates all the Sorbet type signatures based on current code.
  - `rake db:seed` - Creates fake data, mostly for development.

## GitLab CI

To update the Docker container used by GitLab CI:

- Log into the GitLab CI Docker registry with `docker login registry.gitlab.com` (you'll need to use a Personal Access Token as your password).
- Build the container with `docker build -f Dockerfile -t registry.gitlab.com/connorshea/vglist .`
  - You may want to add `--no-cache` to fully rebuild the container from scratch.
- Then use `docker push registry.gitlab.com/connorshea/vglist` to push the container to the GitLab Container Registry.

## Design Document

See [DESIGN_DOC.md](DESIGN_DOC.md) for the general design plan for this project.

## App Structure Visualization

You can see the app visualization locally at `app-visualization.svg` if you run the DB migration. It's not committed here because it changes too often.

Generated by [rails-erd](https://github.com/voormedia/rails-erd).
