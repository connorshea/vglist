# syntax=docker/dockerfile:1
#
# Production image for the vglist Rails API.
#
# Build (from the repo root):
#   docker build -t vglist-api .
#
# Run:
#   docker run -p 3000:3000 \
#     -e RAILS_MASTER_KEY=... -e DATABASE_URL=postgres://... \
#     -e FRONTEND_URL=https://vglist.co \
#     vglist-api
#
# Run migrations before each release with the same image (App Platform does
# this in the PRE_DEPLOY `migrate` job). Use db:migrate, not db:prepare: on an
# empty database db:prepare would also run the dev-only db/seeds.rb.
#   docker run --rm -e RAILS_MASTER_KEY=... -e DATABASE_URL=... -e FRONTEND_URL=... \
#     vglist-api bundle exec rails db:migrate
#
# The Vue frontend has its own image, see frontend/Dockerfile.

# ---------------------------------------------------------------------------
# Base: Ruby plus the shared libraries the app needs at runtime.
# ---------------------------------------------------------------------------
# Pinned by digest so every build uses the exact same base. Dependabot
# (docker ecosystem) bumps the tag and digest together; keep the Ruby
# version in step with mise.toml, Gemfile and the CI workflows.
FROM ruby:4.0.9-slim-trixie@sha256:22cfdec4c490b9e7e4913527a126ddc34bf30cf5432711f70eb1aa4b3ac388a5 AS base

WORKDIR /rails

# - libvips42t64: Active Storage image variants via ruby-vips. Trixie ships
#   libvips 8.16, which satisfies image_processing's >= 8.13 requirement.
# - libpq5: PostgreSQL client library for the pg gem.
# - postgresql-client: psql, which `db:schema:load` shells out to when loading
#   db/structure.sql into an empty database (the Docker CI workflow does
#   this). Trixie's default is v17.
# - libjemalloc2: lower memory fragmentation for Puma's threads/workers.
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y \
      libjemalloc2 \
      libpq5 \
      libvips42t64 \
      postgresql-client && \
    ln -s /usr/lib/$(uname -m)-linux-gnu/libjemalloc.so.2 /usr/local/lib/libjemalloc.so && \
    rm -rf /var/lib/apt/lists/* /var/cache/apt/archives

ENV RAILS_ENV=production \
    RAILS_LOG_TO_STDOUT=1 \
    BUNDLE_DEPLOYMENT=1 \
    BUNDLE_PATH=/usr/local/bundle \
    BUNDLE_WITHOUT=development:test \
    LD_PRELOAD=/usr/local/lib/libjemalloc.so

# ---------------------------------------------------------------------------
# Build: compile native gems and precompile bootsnap caches.
# ---------------------------------------------------------------------------
FROM base AS build

RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y \
      build-essential \
      git \
      libpq-dev \
      libyaml-dev \
      pkg-config && \
    rm -rf /var/lib/apt/lists/* /var/cache/apt/archives

COPY Gemfile Gemfile.lock ./
RUN bundle install && \
    rm -rf ~/.bundle/ "${BUNDLE_PATH}"/ruby/*/cache "${BUNDLE_PATH}"/ruby/*/bundler/gems/*/.git && \
    bundle exec bootsnap precompile --gemfile

COPY . .

RUN bundle exec bootsnap precompile app/ lib/

# ---------------------------------------------------------------------------
# Final runtime image.
# ---------------------------------------------------------------------------
FROM base

COPY --from=build "${BUNDLE_PATH}" "${BUNDLE_PATH}"
COPY --from=build /rails /rails

# Run as an unprivileged user; only runtime-writable dirs are theirs.
RUN groupadd --system --gid 1000 rails && \
    useradd rails --uid 1000 --gid 1000 --create-home --shell /bin/bash && \
    mkdir -p log tmp/pids storage && \
    chown -R rails:rails log tmp storage
USER 1000:1000

EXPOSE 3000

# Platforms like DigitalOcean App Platform run their own HTTP health check
# against /health; this one is for plain `docker run` / Compose. /health is
# exempt from the force_ssl redirect in config/environments/production.rb.
HEALTHCHECK --interval=30s --timeout=5s --start-period=60s --retries=3 \
  CMD ruby -rnet/http -e 'exit Net::HTTP.get_response(URI("http://127.0.0.1:#{ENV.fetch("PORT", 3000)}/health")).is_a?(Net::HTTPSuccess)'

# Puma reads PORT, RAILS_MAX_THREADS and WEB_CONCURRENCY (see config/puma.rb).
CMD ["bundle", "exec", "puma", "-C", "config/puma.rb"]
