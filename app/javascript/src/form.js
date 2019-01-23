import Vue from 'vue/dist/vue.esm';
import GameForm from './components/game-form.vue';
import ReleaseForm from './components/release-form.vue';

document.addEventListener('turbolinks:load', () => {
  let gameFormElement = document.getElementById("game-form")
  if (gameFormElement !== null) {
    const gameFormVue = new Vue({
      el: '#game-form',
      components: { GameForm }
    })
  }

  let releaseFormElement = document.getElementById("release-form")
  if (releaseFormElement !== null) {
    const releaseFormVue = new Vue({
      el: '#release-form',
      components: { ReleaseForm }
    })
  }
});
