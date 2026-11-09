import { createApp } from "vue";
import { createPinia } from "pinia";
import * as Sentry from "@sentry/vue";
import App from "./App.vue";
import router from "./router";
import { dropHandledChunkErrors } from "./utils/sentry-filter";

import "./assets/stylesheets/application.scss";

const app = createApp(App);

Sentry.init({
  app,
  dsn: import.meta.env.VITE_SENTRY_DSN,
  // The commit SHA, same as the API, so both projects share releases.
  release: import.meta.env.VITE_SENTRY_RELEASE,
  integrations: [Sentry.browserTracingIntegration({ router })],
  // Trace 5% of page loads and navigations. Each trace's spans count against
  // the monthly span quota, so keep this low.
  tracesSampleRate: 0.05,
  // Send the trace headers (sentry-trace, baggage) on API requests so a
  // traced page load continues into the Rails trace, and the API follows the
  // same sampling decision. The API's CORS config allows any request header.
  tracePropagationTargets: [import.meta.env.VITE_API_URL],
  enabled: !!import.meta.env.VITE_SENTRY_DSN,
  beforeSend: dropHandledChunkErrors
});

app.use(createPinia());
app.use(router);

app.mount("#app");
