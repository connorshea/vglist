import Vue from 'vue/dist/vue.esm';
import Search from './components/search.vue';

document.addEventListener('turbolinks:load', () => {
  let navbarWithSearch = document.getElementById("navbar-with-search");
  if (navbarWithSearch !== null) {
    const searchVue = new Vue({
      el: '#navbar-with-search',
      components: { Search }
    })
  }
});
