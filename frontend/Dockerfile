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

ARG NODE_VERSION=24
ARG PNPM_VERSION=11.10.0
ARG CADDY_VERSION=2.11

# ---------------------------------------------------------------------------
# Build the static bundle.
# ---------------------------------------------------------------------------
FROM node:${NODE_VERSION}-trixie-slim AS build

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
RUN [ -n "$VITE_API_URL" ] || unset VITE_API_URL; \
    [ -n "$VITE_SENTRY_DSN" ] || unset VITE_SENTRY_DSN; \
    [ -n "$VITE_TURNSTILE_SITE_KEY" ] || unset VITE_TURNSTILE_SITE_KEY; \
    pnpm run build

# ---------------------------------------------------------------------------
# Serve with Caddy.
# ---------------------------------------------------------------------------
FROM caddy:${CADDY_VERSION}-alpine

COPY frontend/Caddyfile /etc/caddy/Caddyfile
COPY --from=build /app/frontend/dist /app/dist

# Listen on an unprivileged port and drop root. The Caddyfile reads PORT.
ENV PORT=8080
RUN chown -R 1000:1000 /data /config
USER 1000:1000

EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD wget -qO- "http://127.0.0.1:${PORT}/health" >/dev/null || exit 1

CMD ["caddy", "run", "--config", "/etc/caddy/Caddyfile", "--adapter", "caddyfile"]
