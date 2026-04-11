/// <reference types="vite/client" />

declare module "*.vue" {
  import type { DefineComponent } from "vue";
  const component: DefineComponent<Record<string, unknown>, Record<string, unknown>, unknown>;
  export default component;
}

interface ImportMetaEnv {
  readonly VITE_API_URL: string;
  readonly VITE_APP_TITLE: string;
  readonly VITE_SENTRY_DSN?: string;
}

interface ImportMeta {
  readonly env: ImportMetaEnv;
}
