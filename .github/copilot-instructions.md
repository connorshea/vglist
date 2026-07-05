# Copilot Instructions for vglist

## Project Overview

- **vglist** is a Ruby on Rails application for tracking video game libraries, user progress, and game metadata. It features a REST API (and GraphQL API), a standalone Vue.js SPA frontend (always use Composition API, `<script setup>`), and Postgres database.
- Key files: `app/models/`, `app/controllers/`, `app/graphql/`, `frontend/src/` (Vite + Vue SPA: `components/`, `pages/`, `router/`, `stores/`, `graphql/`), `db/migrate/`, `config/routes.rb`, `DESIGN_DOC.md`.

## Architecture & Data Flow

- **Rails backend**: Handles business logic, authentication (Devise), authorization (Pundit), and data import (Wikidata, PCGamingWiki, MobyGames, IGDB).
- **Frontend**: A standalone Vite-bundled Vue.js 3.x SPA in `frontend/` (always use Composition API, `<script setup>`), TypeScript for type safety, `vue-router` for client-side routing, Pinia for state (`frontend/src/stores/`), Bulma for styling.
- **GraphQL API**: Defined in `app/graphql/`, exposed for frontend and external integrations.
- **ActiveStorage**: Used for image uploads (avatars, covers).
- **Search**: PgSearch for full-text search, indices rebuilt via Rake tasks.

## Developer Workflows

- **Setup**: See `CONTRIBUTING.md` for environment setup. Key commands:
  - `bundle install`, `pnpm --dir frontend install`, `bundle exec rails db:setup`
  - `./bin/dev` (starts Rails + the Vite dev server, an AI agent should not ever run this on a developer's local machine)
- **Testing**: RSpec for backend (`bundle exec rspec`). Frontend uses Vitest — colocated `*.test.ts` files alongside components in `frontend/src/`, run via `pnpm --dir frontend test`.
- **Type Checking**: Use `pnpm --dir frontend run typecheck` (`vue-tsc`) for TypeScript/Vue type checks.
- **Imports**: Data import via Rake tasks.
- **GraphQL**: Schema in `app/graphql/`; frontend queries/mutations live in `frontend/src/graphql/` and run through `graphql-request` (see the `useGraphQL` composable and `src/graphql/client.ts`). Types are generated with graphql-codegen via `pnpm --dir frontend run codegen`.
- **pnpm**: Use `pnpm` for managing JS dependencies, scripts in `package.json`. Do not use npm or yarn.

## Project-Specific Patterns

- **Vue Components**: Use Composition API and `<script setup>`. Props follow `modelValue`/`update:modelValue` for v-model. Prefer TypeScript for all new components.
- **TypeScript Types**: Extend HTML attributes for new standards (e.g., `popover`) in `frontend/src/types/`. Use interface merging, not overrides.
- **Authentication**: Devise for users, Doorkeeper for OAuth tokens.
- **Authorization**: Pundit policies in `app/policies/`.
- **Data Imports**: Rake tasks for Wikidata, PCGamingWiki, MobyGames, IGDB. API keys via environment variables.
- **Testing Factories**: FactoryBot in `spec/factories/`.

## Integration Points

- **External APIs**: Steam, MobyGames, IGDB (API keys required, see `CONTRIBUTING.md`, but an AI agent should not use these anyway).
- **Vite**: Config in `frontend/vite.config.ts`; frontend source lives in `frontend/src/`. Rails-served assets are in `app/assets/`.

## Conventions & Gotchas

- **Database**: Postgres 17.x required. Use structure.sql for schema.
- **Images**: ActiveStorage for uploads, libvips required.
- **Testing**: Use RSpec for Ruby, prefer TypeScript for Vue tests.
- **TypeScript**: Strict mode enforced.
- **Deployment**: Dockerfile for CI/CD, Rake tasks for production deploy.

## Examples

- See `app/graphql/` for GraphQL schema and resolver patterns.
- See `spec/` for RSpec and FactoryBot usage.

---

For more details, see `CONTRIBUTING.md` and `DESIGN_DOC.md`. If any section is unclear or missing, please provide feedback to improve these instructions.
