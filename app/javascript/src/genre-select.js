import Vue from 'vue/dist/vue.esm';
import GenreSelect from './components/genre-select.vue';

document.addEventListener('turbolinks:load', () => {
  let genreSelect = document.getElementById("genre-select")
  if (genreSelect !== null) {
    const genreSelect = new Vue({
      el: '#genre-select',
      components: { GenreSelect }
    })
  }
});
