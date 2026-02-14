<template>
  <div
    v-if="gamesCountIsPositive && !isLoading && statistics"
    class="card stats-card is-two-thirds column m-auto mt-10"
    :style="{ 'min-height': '200px' }"
  >
    <nav class="level is-fullwidth pb-0">
      <div class="level-item has-text-centered">
        <div>
          <p class="title">{{ statistics.games_count }}</p>
          <p v-if="statistics.games_count === 1" class="heading">Game</p>
          <p v-else class="heading">Games</p>
        </div>
      </div>
      <div class="level-item has-text-centered">
        <div>
          <p v-if="completionRateExists" class="title">{{ statistics.percent_completed }}%</p>
          <p v-else class="title has-text-muted">N/A%</p>
          <p class="heading">Completed</p>
        </div>
      </div>
      <div class="level-item has-text-centered">
        <div>
          <p v-if="averageRatingExists" class="title">{{ statistics.average_rating }}</p>
          <p v-else class="title has-text-muted">N/A</p>
          <p class="heading">Average Rating</p>
        </div>
      </div>
      <div v-if="daysPlayedIsPositive" class="level-item has-text-centered">
        <div>
          <p class="title">{{ statistics.total_days_played }}</p>
          <p class="heading">Days Played</p>
        </div>
      </div>
    </nav>
    <hr v-if="completionRateExists">
    <div v-if="completionRateExists" class="has-text-centered has-text-weight-bold mb-5">Completion</div>
    <div v-if="completionRateExists" class="percentage-bar">
      <div
        v-for="(v, k, i) in statistics.completion_statuses"
        :key="k"
        :id="`completion-status-${i}`"
        :class="['percentage-bar-portion', `color-${i + 1}`]"
        :style="{ 'max-width': (completionStatusesCount ? ((v / completionStatusesCount) * 100) : 0) + '%' }"
        @mouseenter="showPopover(i)"
        @mouseleave="hidePopover(i)"
        :aria-label="`${startCase(k)}: ${v}`"
      >
        <div
          :id="`popover-${i}`"
          class="tooltip"
          popover="auto"
          data-tooltip-placement="top"
        >
          <div class="tooltip-arrow"></div>
          <div class="tooltip-inner">
            {{ startCase(k) }} ({{ v }})
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import Rails from '@rails/ujs';
import { startCase } from 'lodash-es';
import { computed, onBeforeMount, ref } from 'vue';

type Statistics = {
  games_count: number;
  average_rating: number | null;
  percent_completed: number | null;
  total_days_played: number | null;
  completion_statuses: {
    unplayed: number;
    in_progress: number;
    dropped: number;
    completed: number;
    fully_completed: number;
    not_applicable: number;
    paused: number;
    unknown: number;
  } | null;
};

const props = defineProps<{ userId: string }>();
const statistics = ref<Statistics | null>(null);
const isLoading = ref(true);

const getStatistics = () => {
  fetch(`/users/${props.userId}/statistics.json`)
    .then(response => {
      return response.json();
    })
    .then(stats => {
      statistics.value = stats;
      isLoading.value = false;
    });
};

const showPopover = (i: number) => {
  // Do not display the popovers if the browser doesn't support anchoring.
  // TODO: Remove this check when Firefox fully supports CSS Anchoring.
  if (!CSS.supports('anchor-name: none') || !CSS.supports('position-anchor: auto')) {
    return;
  }
  const pop = document.getElementById(`popover-${i}`);
  const status = document.getElementById(`completion-status-${i}`);
  if (pop && status) {
    status.style.anchorName = `--popover-anchor`;
    pop.showPopover?.();
  }
}

const hidePopover = (i: number) => {
  // Do not display the popovers if the browser doesn't support anchoring.
  if (!CSS.supports('anchor-name: none') || !CSS.supports('position-anchor: auto')) {
    return;
  }
  const pop = document.getElementById(`popover-${i}`);
  const status = document.getElementById(`completion-status-${i}`);
  if (pop && status) {
    status.style.anchorName = 'none';
    pop.hidePopover?.();
  }
}

const completionStatusesCount = computed(() => {
  if (statistics.value) {
    const values = Object.values(statistics.value.completion_statuses ?? {});
    return values.reduce((accumulator: number, currentValue: number) => {
      return accumulator + currentValue;
    });
  } else {
    return null;
  }
});

const averageRatingExists = computed(() => {
  return statistics.value?.average_rating !== null;
});

const completionRateExists = computed(() => {
  return statistics.value?.completion_statuses !== null;
});

const daysPlayedIsPositive = computed(() => {
  return (statistics.value?.total_days_played ?? 0) > 0;
});

const gamesCountIsPositive = computed(() => {
  return (statistics.value?.games_count ?? 0) > 0;
});

onBeforeMount(() => getStatistics());
</script>
