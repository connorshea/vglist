// This file is automatically compiled by Webpack, along with any other files
// present in this directory. You're encouraged to place your actual application logic in
// a relevant structure within app/javascript and only use these pack files to reference
// that code so it'll be compiled.

import Rails from '@rails/ujs';
import Turbolinks from 'turbolinks';
import * as ActiveStorage from '@rails/activestorage';
import '../assets/stylesheets/application.scss';
import * as Sentry from "@sentry/vue";
import './src/vue-loader';
import './src/toggleable-buttons';
import './src/bulma';
import './src/settings';

if (process.env.NODE_ENV === 'production') {
  Sentry.init({
    dsn: process.env.SENTRY_DSN_JS,
    environment: process.env.NODE_ENV
  });
}

Rails.start();
Turbolinks.start();
ActiveStorage.start();
