import Rails from "@rails/ujs";
import Turbolinks from "turbolinks";
import * as ActiveStorage from "@rails/activestorage";
import "vue3-select-component/styles";
import "../assets/stylesheets/application.scss";
import * as Sentry from "@sentry/vue";
import "./src/vue-loader";
import "./src/toggleable-buttons";
import "./src/bulma";
import "./src/settings";

if (import.meta.env.PROD) {
  Sentry.init({
    dsn: SENTRY_DSN_JS,
    environment: import.meta.env.MODE
  });
}

Rails.start();
Turbolinks.start();
ActiveStorage.start();
