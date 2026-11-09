import { createApp, watch } from "vue";
import { createPinia } from "pinia";
import * as Sentry from "@sentry/vue";
import App from "./App.vue";
import router from "./router";
import { useAuthStore } from "./stores/auth";
import { beforeSend, beforeSendTransaction } from "./utils/sentry-filter";

import "./assets/stylesheets/application.scss";

const app = createApp(App);

Sentry.init({
  app,
  dsn: import.meta.env.VITE_SENTRY_DSN,
  // The commit SHA, same as the API, so both projects share releases.
  release: import.meta.env.VITE_SENTRY_RELEASE,
  integrations: [
    Sentry.browserTracingIntegration({ router }),
    // Every API request is POST /graphql, so add the operation (e.g. "query
    // GetGame") to request breadcrumbs and spans. Only the operation's name
    // and type are added, never its variables. The query document is left
    // out too, since that's off by default.
    Sentry.graphqlClientIntegration({ endpoints: [`${import.meta.env.VITE_API_URL}/graphql`] })
  ],
  // Trace 25% of page loads and navigations. Each trace's spans count against
  // the monthly span quota, so watch usage if this is raised further.
  tracesSampleRate: 0.25,
  // Send the trace headers (sentry-trace, baggage) on API requests so a
  // traced page load continues into the Rails trace, and the API follows the
  // same sampling decision. The API's CORS config allows any request header.
  tracePropagationTargets: [import.meta.env.VITE_API_URL],
  enabled: !!import.meta.env.VITE_SENTRY_DSN,
  // Drops handled chunk errors and scrubs tokens (e.g. the password reset
  // token in the URL) from errors, breadcrumbs, and span attributes.
  beforeSend,
  beforeSendTransaction
});

const pinia = createPinia();
app.use(pinia);

// Tag events with the signed-in user, like the API does. Only the id and
// username: sendDefaultPii is off, so no email or IP address.
const auth = useAuthStore(pinia);
watch(
  () => auth.user,
  (user) => Sentry.setUser(user ? { id: user.id, username: user.username } : null),
  { immediate: true }
);

app.use(router);

app.mount("#app");
