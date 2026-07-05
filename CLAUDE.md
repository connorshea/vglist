# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

vglist is a Ruby on Rails application for tracking video game libraries. It uses a Rails 7.2 backend with PostgreSQL 17, a standalone Vue 3 + TypeScript SPA frontend (in `frontend/`, bundled with Vite), and exposes both REST and GraphQL APIs.

## Common Commands

### Development

```bash
./bin/dev                      # Start Rails server + Vite dev server (do NOT run this as an AI agent)
bundle install                 # Install Ruby dependencies
pnpm --dir=frontend install    # Install JS dependencies (always use pnpm, never npm or yarn)
```

### Testing

```bash
bundle exec rspec                                              # Full test suite (single process)
bundle exec rspec spec/models/game_spec.rb                     # Single file
bundle exec rspec spec/models/game_spec.rb:42                  # Single example by line
```

The suite is diffuse (no single slow test), so the fastest win is running it across
multiple processes with `parallel_tests`. Each process gets its own database
(`vglist_test`, `vglist_test2`, ...) via the `TEST_ENV_NUMBER` suffix in
`config/database.yml`. CI runs this way by default.

```bash
# One-time (and after schema changes): create + load a DB per process.
bundle exec rake parallel:create parallel:load_schema

bundle exec rake parallel:spec                                 # Run the whole suite in parallel
bundle exec parallel_rspec spec/models spec/requests           # Run specific dirs/files in parallel
```

### Linting & Type Checking

```bash
bundle exec rubocop           # Ruby linting
# All pnpm commands should be run from the frontend directory or with --dir=frontend.
pnpm run lint                  # JS/TS linting (oxlint with type awareness)
pnpm run fmt:check             # Check JS/TS formatting (oxfmt)
pnpm run fmt                   # Auto-format JS/TS
pnpm run typecheck             # TypeScript + Vue type checking (vue-tsc)
```

### Frontend tests

```bash
pnpm --dir=frontend test       # Run the Vitest suite (colocated *.test.ts files under frontend/src/)
pnpm --dir=frontend run test:watch  # Watch mode
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

The frontend is a standalone Vite-bundled Vue 3 SPA living in `frontend/`, with client-side routing (vue-router) and its own `package.json`. It talks to the backend over the GraphQL API.

- **Components**: `frontend/src/components/` — Vue 3 SFCs
- **Pages/routes**: `frontend/src/pages/` and `frontend/src/router/` — vue-router route components
- **State**: `frontend/src/stores/` — Pinia stores
- **Composables**: `frontend/src/composables/` — e.g. `useGraphQL` (data fetching via `graphql-request`)
- **GraphQL**: `frontend/src/graphql/` — queries/mutations and the client (`client.ts`); codegen types via `pnpm --dir=frontend run codegen`
- **Types**: `frontend/src/types/` — TypeScript type definitions
- **Entry point**: `frontend/src/main.ts`
- **Styling**: Bulma CSS framework with Sass/SCSS (`frontend/src/assets/stylesheets/`)

### Tests

- **Backend**: RSpec with FactoryBot (`spec/factories/`), Shoulda Matchers, Pundit matchers
- **Backend structure**: `spec/models/`, `spec/requests/`, `spec/policies/`
- **Frontend**: Vitest with `@vue/test-utils`, colocated `*.test.ts` files under `frontend/src/`

## Key Conventions

- **Package manager**: pnpm only. **Never use `npx`**, and *definitely* never use `npx --yes` — pulling arbitrary packages at runtime hides supply-chain risk, breaks reproducible builds, and bypasses the lockfile. If you need a CLI tool, add it to `frontend/package.json` devDependencies and expose it via a `scripts` entry (e.g. `"lint:schema": "graphql-schema-linter ../schema.graphql"`), then invoke it with `pnpm run <script>` (or `pnpm --dir frontend run <script>` from the repo root). This applies to CI, rake tasks, deploy scripts, and local commands.
- **Vue components**: Always use Composition API with `<script setup>` and TypeScript. Props use `modelValue`/`update:modelValue` for v-model.
- **TypeScript**: Strict mode enforced. No `any` types.
- **Database schema**: Uses `structure.sql` (not `schema.rb`) because of SQL views.
- **Accessibility**: Pages should be accessible and keyboard-navigable wherever possible. Use semantic HTML, ARIA attributes (e.g. `role="dialog"`, `aria-modal`, `aria-label`), visible focus styles (`:focus-visible`), focus trapping in modals/overlays, and ensure all interactive elements are reachable via Tab.
- **Icons**: Use [Lucide](https://lucide.dev/icons/) icons via `@lucide/vue`. Do not create custom SVG icon components — import icons directly from `@lucide/vue` instead.
- **CI checks**: Rubocop, Oxlint, Oxfmt, TypeScript (tsc + vue-tsc), GraphQL schema lint, RSpec (unit + feature separately).

## Parallel Worktrees

vglist supports running multiple git worktrees in parallel (e.g. for parallel agents) without stepping on each other's data. The main checkout at `~/code/vglist` keeps using ports 3000/5173 and the canonical `vglist_development` / `vglist_test` databases unchanged. Each *worktree* gets its own port pair and per-worktree databases via a `.env.local` file.

```bash
# After creating a new worktree:
git worktree add .claude/worktrees/my-feature -b my-feature
cd .claude/worktrees/my-feature
bin/setup-worktree                # picks free ports, creates DBs, loads schema

bin/dev                            # uses the per-worktree ports
bundle exec rspec                  # uses the per-worktree test database

# When done with the worktree:
bin/teardown-worktree              # drops the per-worktree DBs and .env.local
cd ~/code/vglist
git worktree remove .claude/worktrees/my-feature
```

`bin/setup-worktree` is idempotent and refuses to run from the main checkout. `bin/teardown-worktree` refuses to drop any database whose name doesn't have a per-worktree suffix, so the canonical DBs are protected. Both scripts also accept `--force` to override the main-checkout guard.
