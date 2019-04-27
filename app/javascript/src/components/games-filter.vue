<template>
  <div>
    <single-select
      v-model="filter.platform"
      :search-path-identifier="'platforms'"
      :grandparent-class="'games-filter'"
      :parent-class="''"
    ></single-select>
  </div>
</template>

<script>
import SingleSelect from './fields/single-select.vue';
import Rails from 'rails-ujs';

export default {
  name: 'games-filter',
  components: {
    SingleSelect
  },
  data() {
    return {
      filter: {
        platform: null
      }
    };
  },
  methods: {
    onChange(file) {}
  },
  created: function() {
    let currentUrl = new URL(window.location.href);
    let currentUrlParams = currentUrl.searchParams;
    console.log(currentUrlParams);
  }
};
</script>
