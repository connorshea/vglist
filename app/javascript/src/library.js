import Vue from 'vue';
import Library from './components/library.vue';

document.addEventListener('turbolinks:load', () => {
  let gameLibrary = document.getElementById("game-library")
  if (gameLibrary !== null) {
    const library = new Vue({
      el: '#game-library',
      render: h => h(Library)
    })
  }
});
