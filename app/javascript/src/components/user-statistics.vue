<template>
  <div
    v-if="gamesCountIsPositive"
    class="card stats-card is-two-thirds column m-auto mt-10"
    :style="{ 'min-height': '200px' }"
  >
    <nav class="level is-fullwidth pb-0">
      <div class="level-item has-text-centered">
        <div>
          <p class="title">{{ statistics.games_count }}</p>
          <p class="heading">Games</p>
        </div>
      </div>
      <div class="level-item has-text-centered">
        <div>
          <p v-if="completionRateExists" class="title">{{ statistics.percent_completed }}%</p>
          <p v-else class="title has-text-grey-light">N/A%</p>
          <p class="heading">Completed</p>
        </div>
      </div>
      <div class="level-item has-text-centered">
        <div>
          <p v-if="averageRatingExists" class="title">{{ statistics.average_rating }}</p>
          <p v-else class="title has-text-grey-light">N/A</p>
          <p class="heading">Average Rating</p>
        </div>
      </div>
      <div class="level-item has-text-centered">
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
        :class="['percentage-bar-portion', `color-${i + 1}`]"
        :style="{ 'max-width': ((v / completionStatusesCount) * 100) + '%' }"
        v-tooltip="{ content: `${startCase(k)} (${v})` }"
      ></div>
    </div>
  </div>
</template>

<script>
import Rails from 'rails-ujs';

export default {
  name: 'user-statistics',
  props: {
    userId: {
      type: String,
      required: true
    }
  },
  data: function() {
    return {
      statistics: null
    };
  },
  methods: {
    startCase(val) {
      return _.startCase(val);
    },
    getStatistics() {
      fetch(`/users/${this.userId}/statistics.json`)
        .then(response => {
          return response.json();
        })
        .then(statistics => {
          this.statistics = statistics;
        });
    }
  },
  beforeMount: function() {
    this.getStatistics();
  },
  computed: {
    completionStatusesCount: function() {
      if (this.statistics) {
        let values = Object.values(this.statistics.completion_statuses);
        return values.reduce((accumulator, currentValue) => {
          return accumulator + currentValue;
        });
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
    gamesCountIsPositive: function() {
      if (this.statistics) {
        return this.statistics.games_count > 0;
      } else {
        return false;
      }
    }
  }
};
</script>
