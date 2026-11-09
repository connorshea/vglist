import { defineConfig, loadEnv } from "vite";
import vue from "@vitejs/plugin-vue";
import { sentryVitePlugin } from "@sentry/vite-plugin";
import { resolve } from "path";

export default defineConfig(({ mode }) => {
  // Per-worktree overrides come from frontend/.env.local (written by
  // bin/setup-worktree). Defaults match the canonical main-checkout values so
  // the main checkout works with no .env.local present.
  //
  // loadEnv reads frontend/.env, .env.local, .env.<mode>, .env.<mode>.local
  // and returns ALL keys (the third arg "" disables the VITE_ prefix filter).
  // process.env wins so bin/dev's exported values from the root .env.local
  // override anything in frontend/.env*.
  const env = { ...loadEnv(mode, process.cwd(), ""), ...process.env };
  const apiTarget = env.VITE_API_URL ?? "http://localhost:3000";
  const vitePort = Number(env.VITE_PORT ?? 5173);

  // Docker workflow builds on main get SENTRY_AUTH_TOKEN (a BuildKit secret,
  // see frontend/Dockerfile) and the commit SHA as the release. Only then are
  // source maps generated, uploaded to Sentry, and deleted again, so they
  // never ship. "hidden" leaves out the sourceMappingURL comment, so browsers
  // don't go looking for them.
  const sentryRelease = env.VITE_SENTRY_RELEASE;
  const sentryAuthToken = env.SENTRY_AUTH_TOKEN;
  const uploadSourceMaps = !!(sentryAuthToken && sentryRelease);

  return {
    // Serve files from the root public/ directory (favicons, manifest, etc.)
    // so they're available at / in both dev and production builds.
    publicDir: resolve(import.meta.dirname, "../public"),
    plugins: [
      vue(),
      // Must stay last.
      uploadSourceMaps &&
        sentryVitePlugin({
          org: "vglist",
          project: "vglist-frontend",
          authToken: sentryAuthToken,
          telemetry: false,
          release: {
            name: sentryRelease,
            // main.ts sets the release from VITE_SENTRY_RELEASE already.
            inject: false,
            // The Deploy workflow attaches commits and finalizes the release
            // once the commit is actually live.
            finalize: false,
            setCommits: false
          },
          sourcemaps: {
            filesToDeleteAfterUpload: ["./dist/**/*.map"]
          }
        })
    ],
    build: {
      sourcemap: uploadSourceMaps ? "hidden" : false
    },
    resolve: {
      alias: {
        "@": resolve(import.meta.dirname, "src")
      }
    },
    server: {
      port: vitePort,
      // Fail loudly instead of silently picking another port — silent fallback
      // would break the CORS origin match against FRONTEND_URL.
      strictPort: true,
      proxy: {
        "/graphql": {
          target: apiTarget,
          changeOrigin: true
        },
        "/api": {
          target: apiTarget,
          changeOrigin: true
        },
        "/rails/active_storage": {
          target: apiTarget,
          changeOrigin: true
        }
      }
    },
    css: {
      preprocessorOptions: {
        scss: {
          api: "modern-compiler"
        }
      }
    }
  };
});
