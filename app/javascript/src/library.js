/* eslint no-console: 0 */
// Run this example by adding <%= javascript_pack_tag 'hello_vue' %> (and
// <%= stylesheet_pack_tag 'hello_vue' %> if you have styles in your component)
// to the head of your layout file,
// like app/views/layouts/application.html.erb.

// The above code uses Vue without the compiler, which means you cannot
// use Vue to target elements in your existing html templates. You would
// need to always use single file components.
// To be able to target elements in your existing html/erb templates,
// comment out the above code and uncomment the below
// Add <%= javascript_pack_tag 'hello_vue' %> to your layout
// Then add this markup to your html template:
//
// <div id='hello'>
//   {{message}}
//   <app></app>
// </div>

import TurbolinksAdapter from './turbolinks-adapter';
import Vue from 'vue/dist/vue.esm';
import Library from './components/library.vue';

Vue.use(TurbolinksAdapter)

document.addEventListener('turbolinks:load', () => {
  let gameLibrary = document.getElementById("game-library")
  if (gameLibrary !== null) {
    const library = new Vue({
      el: '#game-library',
      components: { Library }
    })
  }
});
