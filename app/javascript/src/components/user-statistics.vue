<template>
  <div
    v-if="gamesCountIsPositive && !isLoading"
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
        :style="{ 'max-width': ((v / completionStatusesCount) * 100) + '%' }"
        @mouseenter="showPopover(i)"
        @mouseleave="hidePopover(i)"
        :aria-label="`${startCase(k)}: ${v}`"
      >
        <div
          :id="`popover-${i}`"
          class="tooltip"
          popover
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

<script lang="ts">
import Rails from '@rails/ujs';
import startCase from 'lodash/startCase';
import { defineComponent } from 'vue';

export default defineComponent({
  name: 'user-statistics',
  props: {
    userId: {
      type: String,
      required: true
    }
  },
  data: function() {
    return {
      statistics: null,
      isLoading: true
    };
  },
  methods: {
    startCase(val) {
      return startCase(val);
    },
    getStatistics() {
      fetch(`/users/${this.userId}/statistics.json`)
        .then(response => {
          return response.json();
        })
        .then(statistics => {
          this.statistics = statistics;
          this.isLoading = false;
        });
    },
    showPopover(i: number) {
      // Do not display the popovers if the browser doesn't support anchoring.
      // TODO: Remove this check when Firefox fully supports CSS Anchoring.
      if (!CSS.supports('anchor-name: none') || !CSS.supports('position-anchor: auto')) {
        return;
      }
      const pop = document.getElementById(`popover-${i}`);
      const status = document.getElementById(`completion-status-${i}`);
      if (pop && status) {
        // @ts-ignore Ignore because TypeScript doesn't know about anchorName yet, can re-enable when we upgrade TypeScript in the future.
        status.style.anchorName = `--popover-anchor`;
        pop.showPopover?.();
      }
    },
    hidePopover(i: number) {
      // Do not display the popovers if the browser doesn't support anchoring.
      if (!CSS.supports('anchor-name: none') || !CSS.supports('position-anchor: auto')) {
        return;
      }
      const pop = document.getElementById(`popover-${i}`);
      const status = document.getElementById(`completion-status-${i}`);
      if (pop && status) {
        // @ts-ignore Ditto
        status.style.anchorName = 'none';
        pop.hidePopover?.();
      }
    }
  },
  beforeMount: function() {
    this.getStatistics();
  },
  computed: {
    completionStatusesCount: function() {
      if (this.statistics) {
        let values = Object.values(this.statistics.completion_statuses);
        return values.reduce((accumulator: number, currentValue: number) => {
          return accumulator + currentValue;
        });
      } else {
        return null;
      }
    },
    averageRatingExists: function() {
      if (this.statistics) {
        return this.statistics.average_rating !== null;
      } else {
        return false;
      }
    },
    completionRateExists: function() {
      if (this.statistics) {
        return this.statistics.completion_statuses !== null;
      } else {
        return false;
      }
    },
    daysPlayedIsPositive: function() {
      if (this.statistics) {
        return this.statistics.total_days_played !== null && this.statistics.total_days_played > 0;
      } else {
        return false;
      }
    },
    gamesCountIsPositive: function() {
      if (this.statistics) {
        return this.statistics.games_count > 0;
      } else {
        return false;
      }
    }
  }
});
</script>
