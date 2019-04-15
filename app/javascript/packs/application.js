/* eslint no-console:0 */
// This file is automatically compiled by Webpack, along with any other files
// present in this directory. You're encouraged to place your actual application logic in
// a relevant structure within app/javascript and only use these pack files to reference
// that code so it'll be compiled.

import Rails from 'rails-ujs';
import Turbolinks from 'turbolinks';
import * as ActiveStorage from 'activestorage';
import '../src/application.scss';
import TurbolinksAdapter from '../src/turbolinks-adapter';
import Vue from 'vue/dist/vue.esm';
import '@babel/polyfill';
import 'lodash';
import '../src/library.js';
import '../src/form.js';
import '../src/search.js';
import '../src/toggleable-buttons.js';
import '../src/bulma.js';

Vue.use(TurbolinksAdapter);

Rails.start();
Turbolinks.start();
ActiveStorage.start();
