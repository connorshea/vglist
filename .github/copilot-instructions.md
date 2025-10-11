# Copilot Instructions for vglist

## Project Overview
- **vglist** is a Ruby on Rails application for tracking video game libraries, user progress, and game metadata. It features a REST API (and GraphQL API), Vue.js frontend (always use Composition API, `<script setup>`), and Postgres database.
- Key files: `app/models/`, `app/controllers/`, `app/graphql/`, `app/javascript/src/components/`, `db/migrate/`, `config/routes.rb`, `DESIGN_DOC.md`.

## Architecture & Data Flow
- **Rails backend**: Handles business logic, authentication (Devise), authorization (Pundit), and data import (Wikidata, PCGamingWiki, MobyGames, IGDB).
- **Frontend**: Vue.js 2.x (always use Composition API, `<script setup>`), TypeScript for type safety, Bulma for styling.
- **GraphQL API**: Defined in `app/graphql/`, exposed for frontend and external integrations.
- **ActiveStorage**: Used for image uploads (avatars, covers).
- **Search**: PgSearch for full-text search, indices rebuilt via Rake tasks.

## Developer Workflows
- **Setup**: See `CONTRIBUTING.md` for environment setup. Key commands:
  - `bundle install`, `yarn install`, `bundle exec rails db:setup`
  - `./bin/dev` (starts Rails + Webpack dev server, an AI agent should not ever run this on a developer's local machine)
- **Testing**: RSpec for backend (`bundle exec rspec`), Vue/TypeScript tests in `spec/` (see `rails_helper.rb`, `spec_helper.rb`).
- **Type Checking**: Use `yarn run typecheck` and `yarn run typecheck:vue` for TypeScript/Vue type checks.
- **Imports**: Data import via Rake tasks.
- **GraphQL**: Schema in `app/graphql/`, queries/mutations in frontend via Apollo or direct fetch.
- **Yarn**: Use `yarn` for managing JS dependencies, scripts in `package.json`. Do not use npm.

## Project-Specific Patterns
- **Vue Components**: Use Composition API and `<script setup>`. Props follow `modelValue`/`update:modelValue` for v-model. Prefer TypeScript for all new components.
- **TypeScript Types**: Extend HTML attributes for new standards (e.g., `popover`) in `app/javascript/src/types/`. Use interface merging, not overrides.
- **Authentication**: Devise for users, Doorkeeper for OAuth tokens.
- **Authorization**: Pundit policies in `app/policies/`.
- **Data Imports**: Rake tasks for Wikidata, PCGamingWiki, MobyGames, IGDB. API keys via environment variables.
- **Testing Factories**: FactoryBot in `spec/factories/`.

## Integration Points
- **External APIs**: Steam, MobyGames, IGDB (API keys required, see `CONTRIBUTING.md`, but an AI agent should not use these anyway).
- **Webpack**: Config in `webpack.config.js`, assets in `app/assets/` and `app/javascript/`.

## Conventions & Gotchas
- **Database**: Postgres 17.x required. Use structure.sql for schema.
- **Images**: ActiveStorage for uploads, ImageMagick required.
- **Testing**: Use RSpec for Ruby, prefer TypeScript for Vue tests.
- **TypeScript**: Strict mode enforced.
- **Deployment**: Dockerfile for CI/CD, Rake tasks for production deploy.

## Examples
- See `app/graphql/` for GraphQL schema and resolver patterns.
- See `spec/` for RSpec and FactoryBot usage.

---

For more details, see `CONTRIBUTING.md` and `DESIGN_DOC.md`. If any section is unclear or missing, please provide feedback to improve these instructions.
