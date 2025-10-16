<template>
  <div class="games-filters">
    <single-select
      v-model="platform"
      :search-path-identifier="'platforms'"
      :grandparent-class="'games-filter'"
      :placeholder="'Filter by platform'"
      @update:modelValue="onPlatformInput"
    ></single-select>

    <static-single-select
      v-model="year"
      :placeholder="'Filter by year'"
      :grandparent-class="'year-filter'"
      :options="yearOptions"
      @update:modelValue="onYearInput"
    ></static-single-select>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted } from 'vue';
import SingleSelect from './fields/single-select.vue';
import StaticSingleSelect from './fields/static-single-select.vue';
import Turbolinks from 'turbolinks';
import { range, reverse } from 'lodash-es';

const platform = ref<{ id: string } | undefined>(undefined);
const year = ref<string | undefined>(undefined);

function onPlatformInput(newPlatform: { id: string } | undefined) {
  const currentUrl = new URL(window.location.href);
  const currentUrlParams = currentUrl.searchParams;
  if (newPlatform) {
    currentUrlParams.set('platform_filter', newPlatform.id);
    Turbolinks.visit(`/games?${currentUrlParams.toString()}`);
  } else {
    currentUrlParams.delete('platform_filter');
    Turbolinks.visit(`/games?${currentUrlParams.toString()}`);
  }
}

function onYearInput(newYear: string | undefined) {
  const currentUrl = new URL(window.location.href);
  const currentUrlParams = currentUrl.searchParams;
  if (newYear) {
    currentUrlParams.set('by_year', newYear);
    Turbolinks.visit(`/games?${currentUrlParams.toString()}`);
  } else {
    currentUrlParams.delete('by_year');
    Turbolinks.visit(`/games?${currentUrlParams.toString()}`);
  }
}

onMounted(() => {
  const currentUrl = new URL(window.location.href);
  const currentUrlParams = currentUrl.searchParams;
  const platformId = currentUrlParams.get('platform_filter');

  if (platformId) {
    fetch(`/platforms/${platformId}.json`)
      .then(response => response.json())
      .then(data => {
        platform.value = data;
      });
  }

  const byYear = currentUrlParams.get('by_year');
  if (byYear) {
    year.value = byYear;
  }
});

const yearOptions = computed(() => {
  const currentYear = new Date().getFullYear();
  // Create an array from 1950 to the current year + 2.
  // (it's +3 because the range ends before the end number)
  return reverse(range(1950, currentYear + 3));
});
</script>
