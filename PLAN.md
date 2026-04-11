# Conversion Plan: Rails API-Only + Vue 3/Vite 8 SPA

## Overview

Convert vglist from a Rails hybrid app (server-rendered ERB views with Vue components mounted on DOM elements) into:
- **Backend**: API-only Rails app serving data exclusively via GraphQL (`/graphql`)
- **Frontend**: Standalone Vue 3 SPA in `frontend/` directory, built with Vite 8, using Vue Router for client-side routing

---

## Phase 1: Backend — Convert Rails to API-Only Mode

### 1.1 Switch Rails to API-only configuration
- In `config/application.rb`, change `Rails::Application` to load API-only middleware:
  ```ruby
  config.api_only = true
  ```
- Remove Turbolinks, Rails UJS, ActiveStorage JS from the asset pipeline
- Remove `Propshaft` gem (no longer serving frontend assets)
- Remove `webpack`-related configs, `Procfile.dev` JS entry, `package.json`, `node_modules`, `tsconfig.json`, `webpack.config.js`, etc.

### 1.2 Strip views and view-related code
- Delete `app/views/` entirely (all ERB templates, layouts, partials)
- Delete `app/assets/` (stylesheets, builds, icons, images) — static assets move to the frontend
- Delete `app/javascript/` — all frontend code moves to `frontend/`
- Remove `app/helpers/` view helpers (e.g., `svg_icon`, `active_nav_item`)

### 1.3 Simplify controllers
- Keep `GraphqlController` as the primary API endpoint
- Convert remaining REST controllers into API controllers (inherit from `ActionController::API` or `ApplicationController` which itself inherits from `ActionController::API`)
- Remove `respond_to` HTML format blocks from controllers — only JSON/GraphQL responses
- Remove Pundit `after_action :verify_authorized` for HTML-only actions (keep for API)
- Remove flash message handling, `redirect_to` calls, and `render` view calls
- Decide which REST endpoints to keep (if any) vs. migrate fully to GraphQL

### 1.4 Authentication changes
- **Devise**: Since there are no more server-rendered login/signup pages, switch to API-based auth:
  - Option A: Keep Devise but use `devise-jwt` gem for JWT-based authentication (stateless, no cookies)
  - Option B: Use Doorkeeper OAuth exclusively (already set up) — the SPA gets a token via OAuth flow
  - Option C: Keep Devise session auth with cookie-based CORS (simpler, works if same-origin or with proper CORS)
  - **Recommended**: Option A (`devise-jwt`) for a clean SPA experience — the frontend sends credentials, receives a JWT, and includes it in subsequent requests via `Authorization: Bearer` header
- Remove Devise view-related controllers (`sessions`, `registrations`, `passwords`, `confirmations` custom controllers) and replace with API endpoints that return JSON
- Update `GraphqlController` to authenticate via JWT (or keep the existing multi-method auth)

### 1.5 CORS configuration
- Add `rack-cors` gem to allow the Vue frontend (running on a different port in dev, possibly different domain in prod) to access the API:
  ```ruby
  # config/initializers/cors.rb
  Rails.application.config.middleware.insert_before 0, Rack::Cors do
    allow do
      origins ENV.fetch('FRONTEND_URL', 'http://localhost:5173')
      resource '*',
        headers: :any,
        methods: [:get, :post, :put, :patch, :delete, :options, :head],
        credentials: true
    end
  end
  ```

### 1.6 Route cleanup
- Remove all resource routes that only served HTML views
- Keep: `POST /graphql`, GraphiQL (dev only), Doorkeeper OAuth routes, Devise token auth routes
- Add a health check endpoint (`GET /health`)

### 1.7 GraphQL API completeness audit
- Audit all existing views/controllers to identify data and actions that are only available via REST, not yet exposed in GraphQL
- Key gaps to fill (based on current routes vs. GraphQL schema):
  - **Auth mutations**: sign_up, sign_in, sign_out, reset_password, confirm_email, change_password, update_profile
  - **Settings**: export library, update account settings, API token management
  - **Bulk operations**: bulk_update game_purchases
  - **Admin pages**: dashboard data, unmatched games management
  - **Activity feeds**: ensure activity query covers all the data the current views show
  - **Search**: global search is already in GraphQL — verify it returns everything needed
  - **Static pages**: about page content (can be hardcoded in frontend or served as a simple query)
  - **User profiles**: statistics, compare, favorites, following/followers — verify all data available
  - **File uploads**: Avatar uploads, game covers — need a GraphQL mutation or a dedicated REST upload endpoint (GraphQL file uploads via multipart)

### 1.8 Gem cleanup
- Remove frontend-related gems: `propshaft`, `turbolinks`, `inline_svg`, any view-helper gems
- Remove `jsbundling-rails` if present
- Add: `rack-cors`, `devise-jwt` (if going JWT route)
- Keep: `graphql`, `graphiql-rails` (dev), `devise`, `doorkeeper`, `pundit`, `active_storage`, `sentry-ruby`

---

## Phase 2: Frontend — Create Vue 3/Vite 8 SPA

### 2.1 Initialize the frontend project
```bash
cd /home/user/vglist
npm create vite@latest frontend -- --template vue-ts
# or with yarn:
yarn create vite frontend --template vue-ts
```
- Configure Vite 8 with Vue 3, TypeScript strict mode
- Set up path aliases (`@/` → `src/`)

### 2.2 Install core dependencies
```bash
cd frontend
yarn add vue-router@4 @apollo/client graphql @vue/apollo-composable
yarn add -D @vitejs/plugin-vue typescript vue-tsc
```
- **Vue Router 4**: Client-side routing (replaces Rails routes for page navigation)
- **Apollo Client + @vue/apollo-composable**: GraphQL client (replaces REST fetch calls)
- **Bulma** (or migrate to a different CSS framework): `yarn add bulma sass`

### 2.3 Project structure
```
frontend/
├── index.html                 # Single HTML entry point
├── vite.config.ts
├── tsconfig.json
├── src/
│   ├── main.ts                # App bootstrap (createApp, router, Apollo)
│   ├── App.vue                # Root component (navbar, router-view, flash messages)
│   ├── router/
│   │   └── index.ts           # Vue Router routes (mirrors current Rails routes)
│   ├── graphql/
│   │   ├── client.ts          # Apollo Client setup (endpoint, auth headers)
│   │   ├── queries/           # .graphql or .ts query files
│   │   └── mutations/         # .graphql or .ts mutation files
│   ├── composables/
│   │   ├── useAuth.ts         # Auth state, login/logout, token management
│   │   ├── useCurrentUser.ts  # Current user query
│   │   └── ...
│   ├── components/            # Migrate existing Vue components here
│   │   ├── navbar/
│   │   ├── games/
│   │   ├── users/
│   │   ├── library/
│   │   ├── admin/
│   │   └── shared/
│   ├── pages/                 # Route-level page components (new)
│   │   ├── HomePage.vue
│   │   ├── games/
│   │   │   ├── GameListPage.vue
│   │   │   ├── GameShowPage.vue
│   │   │   └── GameFormPage.vue
│   │   ├── users/
│   │   │   ├── UserShowPage.vue
│   │   │   ├── UserSettingsPage.vue
│   │   │   └── ...
│   │   ├── auth/
│   │   │   ├── LoginPage.vue
│   │   │   ├── SignupPage.vue
│   │   │   └── ...
│   │   ├── admin/
│   │   └── StaticPages/
│   ├── stores/                # Pinia stores (optional, for complex state)
│   │   └── auth.ts
│   ├── types/                 # Migrate existing TypeScript types
│   ├── assets/
│   │   ├── stylesheets/       # Migrate SCSS (Bulma customizations)
│   │   ├── images/            # Migrate static images
│   │   └── icons/             # Migrate SVG icons
│   └── utils/
│       └── ...
```

### 2.4 Routing — map Rails routes to Vue Router
Current Rails routes → Vue Router equivalents:
```typescript
const routes = [
  { path: '/', component: HomePage },
  // Games
  { path: '/games', component: GameListPage },
  { path: '/games/:id', component: GameShowPage },
  { path: '/games/new', component: GameFormPage },
  { path: '/games/:id/edit', component: GameFormPage },
  // Users
  { path: '/users', component: UserListPage },
  { path: '/users/:id', component: UserShowPage },
  { path: '/users/:id/statistics', component: UserStatisticsPage },
  { path: '/users/:id/activity', component: UserActivityPage },
  { path: '/users/:id/favorites', component: UserFavoritesPage },
  { path: '/users/:id/following', component: UserFollowingPage },
  { path: '/users/:id/followers', component: UserFollowersPage },
  { path: '/users/:id/compare/:otherId', component: UserComparePage },
  // Platforms, Companies, Engines, Genres, Series, Stores
  { path: '/platforms', component: PlatformListPage },
  { path: '/platforms/:id', component: PlatformShowPage },
  // ... similar for other resources
  // Auth
  { path: '/login', component: LoginPage },
  { path: '/signup', component: SignupPage },
  { path: '/password/reset', component: PasswordResetPage },
  // Settings
  { path: '/settings', component: SettingsPage, children: [
    { path: 'profile', component: ProfileSettings },
    { path: 'account', component: AccountSettings },
    { path: 'import', component: ImportSettings },
    { path: 'export', component: ExportSettings },
    { path: 'api-token', component: ApiTokenSettings },
    { path: 'oauth', component: OAuthSettings },
  ]},
  // Admin
  { path: '/admin', component: AdminDashboard },
  // Activity
  { path: '/activity', component: ActivityPage },
  // Search
  { path: '/search', component: SearchPage },
  // Static
  { path: '/about', component: AboutPage },
]
```

### 2.5 Apollo Client setup
```typescript
// src/graphql/client.ts
import { ApolloClient, InMemoryCache, createHttpLink } from '@apollo/client/core'
import { setContext } from '@apollo/client/link/context'

const httpLink = createHttpLink({
  uri: import.meta.env.VITE_API_URL + '/graphql',
})

const authLink = setContext((_, { headers }) => {
  const token = localStorage.getItem('auth_token')
  return {
    headers: {
      ...headers,
      authorization: token ? `Bearer ${token}` : '',
    }
  }
})

export const apolloClient = new ApolloClient({
  link: authLink.concat(httpLink),
  cache: new InMemoryCache(),
})
```

### 2.6 Migrate existing Vue components
- Move all components from `app/javascript/src/components/` to `frontend/src/components/`
- Refactor components that relied on `data-vue-props` to instead:
  - Receive props from parent page components
  - Fetch their own data via Apollo/GraphQL composables
  - Use Vue Router params (`useRoute()`) for IDs and context
- Replace REST API calls (`fetch('/games.json')`) with GraphQL queries
- Remove Turbolinks-related code
- Remove Rails UJS dependencies (`@rails/ujs`)
- Replace `svg_icon` helper references with direct SVG imports or a Vue icon component

### 2.7 Authentication flow in the SPA
- **Login page**: POST credentials to API, receive JWT token, store in `localStorage` (or `httpOnly` cookie via a dedicated endpoint)
- **Auth guard**: Vue Router navigation guard checks for valid token before protected routes
- **Token refresh**: Implement token refresh logic if using JWT with expiry
- **Logout**: Clear token, redirect to login page
- **Registration**: POST to API signup endpoint, auto-login on success

### 2.8 Asset migration
- Copy SVG icons from `app/assets/icons/` to `frontend/src/assets/icons/`
- Copy images from `app/assets/images/` to `frontend/src/assets/images/` or `frontend/public/`
- Migrate SCSS from `app/assets/stylesheets/` to `frontend/src/assets/stylesheets/`
- Update import paths in SCSS files
- Vite handles SCSS natively with `sass` package

### 2.9 Environment configuration
```
# frontend/.env.development
VITE_API_URL=http://localhost:3000

# frontend/.env.production
VITE_API_URL=https://api.vglist.co
```

---

## Phase 3: Development Workflow & Deployment

### 3.1 Development setup
- New `Procfile.dev`:
  ```
  api: bin/rails server -p 3000
  web: cd frontend && yarn dev
  ```
- Vite dev server runs on port 5173 (default), proxies API calls to Rails on 3000
- Alternatively, configure Vite proxy in `vite.config.ts`:
  ```typescript
  server: {
    proxy: {
      '/graphql': 'http://localhost:3000',
    }
  }
  ```

### 3.2 Production deployment
- **Backend**: Deploy Rails API as usual (Puma, standard Rails deployment)
- **Frontend**: `cd frontend && yarn build` produces static files in `frontend/dist/`
  - Serve via CDN/Nginx/S3+CloudFront
  - Or have Rails serve the built frontend from `public/` (optional, simpler setup)
  - Nginx config: serve `frontend/dist/` for all routes, with fallback to `index.html` for SPA routing

### 3.3 CI/CD updates
- Split CI into backend and frontend jobs
- Backend: `bundle exec rspec`, `bundle exec rubocop`
- Frontend: `yarn lint`, `yarn fmt:check`, `yarn typecheck:full`, `yarn test` (add Vitest for unit tests)
- E2E tests: Consider Playwright or Cypress (replaces Capybara feature tests)

### 3.4 Monorepo structure
```
vglist/
├── app/                    # Rails API app
├── config/
├── db/
├── spec/                   # Backend tests only (no more feature specs)
├── frontend/               # Vue SPA (its own package.json, vite.config, etc.)
│   ├── src/
│   ├── public/
│   ├── package.json
│   └── vite.config.ts
├── Gemfile
├── Procfile.dev
└── ...
```

---

## Phase 4: Migration Strategy (Recommended Order)

Doing this all at once is a large effort. Here's a recommended incremental approach:

### Step 1: Prepare the GraphQL API (no frontend changes yet)
- Audit and fill all GraphQL gaps (auth mutations, settings, uploads, etc.)
- Add CORS support
- Add JWT/token auth endpoint
- **Test**: Ensure all data and actions are available via GraphQL

### Step 2: Scaffold the Vue SPA
- Create `frontend/` with Vite 8, Vue Router, Apollo Client
- Set up auth flow, basic layout (navbar, footer)
- Create page shells for all routes

### Step 3: Migrate pages incrementally
- Start with simpler pages (about, search, platform/genre/etc. list & show pages)
- Then games (list, show, create/edit)
- Then users (profile, library, settings)
- Then admin pages
- Port existing Vue components, adapting them to fetch via GraphQL

### Step 4: Cut over
- Remove Rails views, Webpack, frontend JS, ERB templates
- Set `config.api_only = true`
- Clean up gems and dependencies
- Update deployment pipeline

---

## Key Risks & Considerations

1. **GraphQL API completeness**: The biggest risk — the current app has many features only accessible via REST/HTML views. All must be exposed via GraphQL before the frontend can fully replace them.

2. **Authentication transition**: Moving from cookie-based Devise sessions to token-based auth requires careful handling of the login flow, token storage (XSS considerations with localStorage vs. httpOnly cookies), and token refresh.

3. **File uploads**: ActiveStorage uploads (avatars, game covers) need a dedicated upload mechanism — either a REST endpoint returning a URL, or GraphQL multipart upload support.

4. **SEO**: The current server-rendered pages are SEO-friendly. A Vue SPA is not (without SSR). If SEO matters for game pages, consider:
   - Adding Nuxt 3 instead of plain Vue (gives SSR/SSG)
   - Using a prerendering service
   - Keeping critical public pages server-rendered

5. **Feature tests**: Current Capybara/Selenium feature tests will need to be rewritten as Playwright/Cypress E2E tests against the SPA.

6. **Turbolinks removal**: Currently provides SPA-like navigation. Vue Router will fully replace this.
