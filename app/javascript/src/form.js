import Vue from 'vue';
import GameForm from './components/game-form.vue';

document.addEventListener('turbolinks:load', () => {
  let gameFormElement = document.getElementById("game-form")
  if (gameFormElement !== null) {
    const gameFormVue = new Vue({
      el: '#game-form',
      render: h => h(GameForm)
    })
  }
});
