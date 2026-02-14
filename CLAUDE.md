# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

vglist is a Ruby on Rails application for tracking video game libraries. It uses a Rails 7.2 backend with PostgreSQL 17, a Vue 3 + TypeScript frontend bundled with Webpack 5, and exposes both REST and GraphQL APIs.

## Common Commands

### Development

```bash
./bin/dev                    # Start Rails server + Webpack dev server (do NOT run this as an AI agent)
bundle install               # Install Ruby dependencies
yarn install                 # Install JS dependencies (always use yarn, never npm)
```

### Testing

```bash
bundle exec rspec                                              # Full test suite
bundle exec rspec --exclude-pattern "spec/features/**/*_spec.rb"  # Unit tests only
bundle exec rspec spec/features                                # Feature tests only
bundle exec rspec spec/models/game_spec.rb                     # Single file
bundle exec rspec spec/models/game_spec.rb:42                  # Single example by line
```

### Linting & Type Checking

```bash
bundle exec rubocop           # Ruby linting
yarn run lint                  # JS/TS linting (oxlint with type awareness)
yarn run fmt:check             # Check JS/TS formatting (oxfmt)
yarn run fmt                   # Auto-format JS/TS
yarn run typecheck             # TypeScript type checking (tsc)
yarn run typecheck:vue         # Vue component type checking (vue-tsc)
yarn run typecheck:full        # Both TypeScript checks
```

### Database

```bash
bundle exec rails db:setup            # Create DB, load schema, seed
bundle exec rails db:migrate          # Run migrations
bundle exec rails db:structure:dump   # Export structure.sql (used instead of schema.rb due to SQL views)
```

### GraphQL

```bash
bundle exec rake graphql:schema:idl   # Regenerate schema.graphql
```

## Architecture

### Backend

- **Models**: `app/models/` — Core entities: Game, User, GamePurchase (user's library entries), Platform, Genre, Company, Series, Engine, Store, plus join models
- **Controllers**: `app/controllers/` — REST endpoints
- **GraphQL**: `app/graphql/` — Types, queries, and mutations. Endpoint at `POST /graphql`
- **Policies**: `app/policies/` — Pundit authorization policies
- **Services**: `app/services/` — Service objects for business logic
- **Auth**: Devise for user authentication, Doorkeeper for OAuth tokens

### Frontend

- **Components**: `app/javascript/src/components/` — Vue 3 SFCs
- **Types**: `app/javascript/src/types/` — TypeScript type definitions
- **Entry point**: `app/javascript/application.ts`
- **Styling**: Bulma CSS framework with Sass/SCSS

### Tests

- **Framework**: RSpec with FactoryBot (`spec/factories/`), Shoulda Matchers, Pundit matchers
- **Feature tests**: Capybara with headless Chrome (Selenium WebDriver)
- **Structure**: `spec/models/`, `spec/requests/`, `spec/features/`, `spec/policies/`

## Key Conventions

- **Vue components**: Always use Composition API with `<script setup>` and TypeScript. Props use `modelValue`/`update:modelValue` for v-model.
- **TypeScript**: Strict mode enforced. No `any` types.
- **Database schema**: Uses `structure.sql` (not `schema.rb`) because of SQL views.
- **CI checks**: Rubocop, Oxlint, Oxfmt, TypeScript (tsc + vue-tsc), GraphQL schema lint, RSpec (unit + feature separately).
