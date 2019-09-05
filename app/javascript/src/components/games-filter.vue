<template>
  <div>
    <single-select
      v-model="platform"
      :search-path-identifier="'platforms'"
      :grandparent-class="'games-filter'"
      :parent-class="''"
      :placeholder="'Filter by platform'"
      @input="onInput"
    ></single-select>
  </div>
</template>

<script lang="ts">
import SingleSelect from './fields/single-select.vue';
import Rails from '@rails/ujs';
import Turbolinks from 'turbolinks';

export default {
  name: 'games-filter',
  components: {
    SingleSelect
  },
  data: function() {
    return {
      platform: null
    };
  },
  methods: {
    // Change the set platform on input, or remove it if it's deleted.
    onInput(platform) {
      let currentUrl = new URL(window.location.href);
      let currentUrlParams = currentUrl.searchParams;
      if (platform) {
        currentUrlParams.set('platform_filter', platform.id);
        Turbolinks.visit(`/games?${currentUrlParams.toString()}`);
      } else {
        currentUrlParams.delete('platform_filter');
        Turbolinks.visit(`/games?${currentUrlParams.toString()}`);
      }
    }
  },
  // On creation, get the name of the platform if the platform
  // filter is set.
  created: function() {
    let currentUrl = new URL(window.location.href);
    let currentUrlParams = currentUrl.searchParams;
    let platformId = currentUrlParams.get('platform_filter');
    if (platformId) {
      fetch(`/platforms/${platformId}.json`)
        .then(response => {
          return response.json();
        })
        .then(platform => {
          this.platform = platform;
        });
    }
  }
};
</script>
