import { defineConfig, loadEnv } from "vite";
import vue from "@vitejs/plugin-vue";
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

  return {
    // Serve files from the root public/ directory (favicons, manifest, etc.)
    // so they're available at / in both dev and production builds.
    publicDir: resolve(__dirname, "../public"),
    plugins: [vue()],
    resolve: {
      alias: {
        "@": resolve(__dirname, "src")
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
