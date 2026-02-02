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
import type { Option } from 'vue3-select-component';
import SingleSelect from './fields/single-select.vue';
import StaticSingleSelect from './fields/static-single-select.vue';
import Turbolinks from 'turbolinks';
import { range, reverse } from 'lodash-es';

const platform = ref<Option<number> | null>(null);
const year = ref<Option<number> | null>(null);

function onPlatformInput(newPlatform: Option<number> | null) {
  const currentUrl = new URL(window.location.href);
  const currentUrlParams = currentUrl.searchParams;
  if (newPlatform) {
    currentUrlParams.set('platform_filter', String(newPlatform.value));
    Turbolinks.visit(`/games?${currentUrlParams.toString()}`);
  } else {
    currentUrlParams.delete('platform_filter');
    Turbolinks.visit(`/games?${currentUrlParams.toString()}`);
  }
}

function onYearInput(newYear: Option<number> | null) {
  const currentUrl = new URL(window.location.href);
  const currentUrlParams = currentUrl.searchParams;
  if (newYear) {
    currentUrlParams.set('by_year', String(newYear.value));
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
      .then((data: { id: number; name: string }) => {
        platform.value = { value: data.id, label: data.name };
      });
  }

  const byYear = currentUrlParams.get('by_year');
  if (byYear) {
    const yearNum = parseInt(byYear, 10);
    year.value = { value: yearNum, label: byYear };
  }
});

const yearOptions = computed((): Option<number>[] => {
  const currentYear = new Date().getFullYear();
  // Create an array from 1950 to the current year + 2.
  // (it's +3 because the range ends before the end number)
  const years = reverse(range(1950, currentYear + 3));
  return years.map(y => ({ value: y, label: String(y) }));
});
</script>
