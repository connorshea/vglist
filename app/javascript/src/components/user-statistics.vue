<template>
  <div class="card is-two-thirds column m-auto mt-10">
    <nav v-if="statistics" class="level stats-card">
      <div class="level-item has-text-centered">
        <div>
          <p class="title">{{ statistics.games_count }}</p>
          <p class="heading">Games</p>
        </div>
      </div>
      <div class="level-item has-text-centered">
        <div>
          <p class="title">{{ statistics.percent_completed }}%</p>
          <p class="heading">Completed</p>
        </div>
      </div>
      <div class="level-item has-text-centered">
        <div>
          <p class="title">{{ statistics.average_rating }}</p>
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
    <div v-if="statistics" class="percentage-bar">
      <div
        v-for="(v, k, i) in statistics.completion_statuses"
        :key="k"
        :class="['percentage-bar-portion', `color-${i + 1}`]"
        :style="{ 'max-width': ((v / completionStatusesCount) * 100) + '%' }"
        v-tooltip="{ content: startCase(k) }"
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
    }
  },
  created: function() {
    fetch(`/users/${this.userId}/statistics.json`)
      .then(response => {
        return response.json();
      })
      .then(statistics => {
        this.statistics = statistics;
      });
  },
  computed: {
    completionStatusesCount: function() {
      if (this.statistics) {
        let values = Object.values(this.statistics.completion_statuses);
        return values.reduce((accumulator, currentValue) => {
          return accumulator + currentValue;
        });
      }
    }
  }
};
</script>
