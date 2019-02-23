<template>
  <div class="field">
    <label class="label">{{ label }}</label>
    <div class="field" v-for="(platform, index) in platforms" :key="platform['id']">
      <!-- <p>platform: {{ platform }}, index: {{ index }}</p>

      <p>{{ platforms[index] }}</p>
      {{ releaseDates[index]['release_date'] }} -->
      <single-select
        v-model="platforms[index]"
        :search-path-identifier="'platforms'"
      ></single-select>
      <input type="date" class="input" v-model="releaseDates[index]['release_date']">
    </div>
  </div>
</template>

<script>
import vSelect from 'vue-select';
import SingleSelect from './single-select.vue';

export default {
  name: 'release-dates-select',
  components: {
    vSelect,
    SingleSelect
  },
  props: {
    label: {
      type: String,
      required: true
    },
    value: {
      type: Array,
      required: true
    }
  },
  data: function() {
    return {
      labels: {
        platforms: 'Platforms'
      },
      releaseDates: this.value,
      platforms: this.platforms
    }
  },
  methods: {
    asyncGetPlatform: async function(platformId) {
      let platform = await this.getPlatform(platformId);
      return platform;
    },
    getPlatform: (platformId) => {
      return fetch(`${window.location.origin}/platforms/${platformId}.json`, {
        headers: {
          "Content-Type": "application/json"
        }
      }).then((response) => {
        return response.json();
      })
      .then((platform) => {
        return platform;
      });
    }
  },
  created() {
    this.platforms = [];
    let platformIds = this.releaseDates.map(x => x['platform_id']);
    platformIds.forEach((platformId) => {
      this.asyncGetPlatform(platformId).then((data) => {
        this.platforms.push(data);
      })
    });
  }
}
</script>
