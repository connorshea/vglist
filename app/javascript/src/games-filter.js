import Vue from 'vue/dist/vue.esm';
import GamesFilter from './components/games-filter.vue';

document.addEventListener('turbolinks:load', () => {
  let gamesFilter = document.getElementById('games-filter');

  if (gamesFilter !== null) {
    const filter = new Vue({
      el: '#games-filter',
      components: { GamesFilter }
    });
  }
});
