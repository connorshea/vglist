/* eslint no-console:0 */
// This file is automatically compiled by Webpack, along with any other files
// present in this directory. You're encouraged to place your actual application logic in
// a relevant structure within app/javascript and only use these pack files to reference
// that code so it'll be compiled.

import Rails from '@rails/ujs';
import Turbolinks from 'turbolinks';
import * as ActiveStorage from '@rails/activestorage';
import '../src/application.scss';
import TurbolinksAdapter from '../src/turbolinks-adapter';
import Vue from 'vue/dist/vue.esm';
import VTooltip from 'v-tooltip';
import 'core-js/stable';
import 'regenerator-runtime/runtime';
import * as Sentry from '@sentry/browser';
import { Vue as VueIntegration } from '@sentry/integrations';
import _ from "lodash";
import '../src/vue-loader';
import '../src/toggleable-buttons';
import '../src/bulma';
import '../src/settings';

// Load the icons directory so it can be discovered and compiled by webpacker.
// @ts-ignore
require.context('../icons', true);

if (process.env.NODE_ENV === 'production') {
  Sentry.init({
    dsn: process.env.SENTRY_DSN_JS,
    integrations: [
      new VueIntegration({ Vue })
    ],
    environment: process.env.NODE_ENV
  });
}

Vue.use(TurbolinksAdapter);
Vue.use(VTooltip);
VTooltip.enabled = window.innerWidth > 768;

Rails.start();
Turbolinks.start();
ActiveStorage.start();
