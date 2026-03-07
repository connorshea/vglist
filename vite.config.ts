import { resolve } from "path";
import { defineConfig } from "vite";
import vue from "@vitejs/plugin-vue";

export default defineConfig(({ mode }) => ({
  build: {
    rollupOptions: {
      input: {
        application: resolve(import.meta.dirname, "app/javascript/application.ts")
      },
      output: {
        entryFileNames: "[name].js",
        // Name the CSS file "application.css" to match the Rails stylesheet_link_tag.
        assetFileNames: (assetInfo) => {
          if (assetInfo.names?.[0]?.endsWith(".css")) {
            return "application[extname]";
          }
          return "[name][extname]";
        },
        // Inline all dynamic imports into the entry chunk for jsbundling-rails compatibility.
        inlineDynamicImports: true
      }
    },
    outDir: resolve(import.meta.dirname, "app/assets/builds"),
    emptyOutDir: true,
    sourcemap: mode === "production",
    assetsInlineLimit: 0,
    cssCodeSplit: false,
    modulePreload: false
  },
  plugins: [
    vue({
      template: {
        compilerOptions: {
          whitespace: "condense"
        }
      }
    })
  ],
  define: {
    SENTRY_DSN_JS: JSON.stringify(process.env.SENTRY_DSN_JS),
    __VUE_OPTIONS_API__: JSON.stringify(true),
    __VUE_PROD_DEVTOOLS__: JSON.stringify(false),
    __VUE_PROD_HYDRATION_MISMATCH_DETAILS__: JSON.stringify(false)
  },
  resolve: {
    extensions: [".ts", ".vue", ".js", ".scss", ".css"]
  }
}));
