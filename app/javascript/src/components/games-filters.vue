<template>
  <div class="games-filters">
    <single-select
      v-model="platform"
      :search-path-identifier="'platforms'"
      :grandparent-class="'games-filter'"
      :placeholder="'Filter by platform'"
      @input="onPlatformInput"
    ></single-select>

    <static-single-select
      v-model="year"
      :placeholder="'Filter by year'"
      :grandparent-class="'year-filter'"
      :options="yearOptions"
      @input="onYearInput"
    ></static-single-select>
  </div>
</template>

<script lang="ts">
import SingleSelect from './fields/single-select.vue';
import StaticSingleSelect from './fields/static-single-select.vue';
import Rails from '@rails/ujs';
import Turbolinks from 'turbolinks';
import * as _ from 'lodash';

export default {
  name: 'games-filters',
  components: {
    SingleSelect,
    StaticSingleSelect
  },
  data: function() {
    return {
      platform: null,
      year: null
    };
  },
  methods: {
    // Change the set platform on input, or remove it if it's deleted.
    onPlatformInput(platform) {
      let currentUrl = new URL(window.location.href);
      let currentUrlParams = currentUrl.searchParams;
      if (platform) {
        currentUrlParams.set('platform_filter', platform.id);
        Turbolinks.visit(`/games?${currentUrlParams.toString()}`);
      } else {
        currentUrlParams.delete('platform_filter');
        Turbolinks.visit(`/games?${currentUrlParams.toString()}`);
      }
    },
    onYearInput(year) {
      let currentUrl = new URL(window.location.href);
      let currentUrlParams = currentUrl.searchParams;
      if (year) {
        currentUrlParams.set('by_year', year);
        Turbolinks.visit(`/games?${currentUrlParams.toString()}`);
      } else {
        currentUrlParams.delete('by_year');
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
    let byYear = currentUrlParams.get('by_year');
    if (byYear) {
      this.year = byYear;
    }
  },
  computed: {
    yearOptions() {
      let currentYear = new Date().getFullYear();
      // Create an array from 1950 to the current year + 2.
      // (it's +3 because the range ends before the end number)
      return _.reverse(_.range(1950, currentYear + 3));
    }
  }
};
</script>
