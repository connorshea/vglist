import { createApp } from "vue";
import { createPinia } from "pinia";
import * as Sentry from "@sentry/vue";
import App from "./App.vue";
import router from "./router";

import "./assets/stylesheets/application.scss";

const app = createApp(App);

Sentry.init({
  app,
  dsn: import.meta.env.VITE_SENTRY_DSN,
  integrations: [Sentry.browserTracingIntegration({ router })],
  enabled: !!import.meta.env.VITE_SENTRY_DSN
});

app.use(createPinia());
app.use(router);

app.mount("#app");
