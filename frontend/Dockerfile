# syntax=docker/dockerfile:1
#
# Production image for the vglist Vue SPA, served by Caddy.
#
# The build context must be the REPO ROOT (not frontend/), because Vite uses
# ../public as its publicDir for favicons, robots.txt, and the web manifest:
#   docker build -f frontend/Dockerfile \
#     --build-arg VITE_API_URL=https://api.vglist.co \
#     --build-arg VITE_SENTRY_DSN=https://...@sentry.io/... \
#     --build-arg VITE_TURNSTILE_SITE_KEY=0x4AAAAAAA... \
#     -t vglist-frontend .
#
# Run (API_ORIGIN feeds the CSP connect-src in frontend/Caddyfile):
#   docker run -p 8080:8080 -e API_ORIGIN=https://api.vglist.co vglist-frontend

ARG PNPM_VERSION=11.10.0

# ---------------------------------------------------------------------------
# Build the static bundle.
# ---------------------------------------------------------------------------
# Base images are pinned by digest; Dependabot bumps tag and digest together.
FROM node:24.22.2-trixie-slim@sha256:0820eaa85e07d0490446dd01d14707e17e6108a36988cf374899cd057eb3812d AS build

ARG PNPM_VERSION
RUN npm install -g "pnpm@${PNPM_VERSION}"

WORKDIR /app/frontend

COPY frontend/package.json frontend/pnpm-lock.yaml ./
RUN pnpm install --frozen-lockfile

COPY public/ /app/public/
COPY frontend/ ./

# Vite inlines VITE_* vars at build time. Unset args fall back to
# frontend/.env.production, so only export the ones that were passed:
# an empty env var would otherwise override the .env.production value.
ARG VITE_API_URL
ARG VITE_SENTRY_DSN
ARG VITE_TURNSTILE_SITE_KEY
ARG VITE_SENTRY_RELEASE
# SENTRY_AUTH_TOKEN is a BuildKit secret (docker build --secret
# id=sentry_auth_token,env=SENTRY_AUTH_TOKEN), so it never lands in a layer or
# the image history. With it and VITE_SENTRY_RELEASE set, vite.config.ts
# uploads hidden source maps to Sentry and deletes them; the find below makes
# sure none reach the Caddy stage either way. A failed upload doesn't fail the
# build; vite.config.ts writes it to SENTRY_UPLOAD_ERRORS_FILE, which goes into
# the image (outside the served dist/) so the Docker workflow can warn about it.
RUN --mount=type=secret,id=sentry_auth_token,env=SENTRY_AUTH_TOKEN \
    [ -n "$VITE_API_URL" ] || unset VITE_API_URL; \
    [ -n "$VITE_SENTRY_DSN" ] || unset VITE_SENTRY_DSN; \
    [ -n "$VITE_TURNSTILE_SITE_KEY" ] || unset VITE_TURNSTILE_SITE_KEY; \
    [ -n "$VITE_SENTRY_RELEASE" ] || unset VITE_SENTRY_RELEASE; \
    export SENTRY_UPLOAD_ERRORS_FILE=/app/sentry-upload-errors; \
    : > "$SENTRY_UPLOAD_ERRORS_FILE"; \
    pnpm run build \
    && find dist -name "*.map" -delete

# ---------------------------------------------------------------------------
# Serve with Caddy.
# ---------------------------------------------------------------------------
FROM caddy:2.11.9-alpine@sha256:0bbb055bda6793c999bde78b1b5ce3e89f829fb031af2cf50056ea1246559fee

COPY frontend/Caddyfile /etc/caddy/Caddyfile
COPY --from=build /app/frontend/dist /app/dist
COPY --from=build /app/sentry-upload-errors /app/sentry-upload-errors

# Listen on an unprivileged port and drop root. The Caddyfile reads PORT.
ENV PORT=8080
RUN chown -R 1000:1000 /data /config
USER 1000:1000

EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD wget -qO- "http://127.0.0.1:${PORT}/health" >/dev/null || exit 1

CMD ["caddy", "run", "--config", "/etc/caddy/Caddyfile", "--adapter", "caddyfile"]
