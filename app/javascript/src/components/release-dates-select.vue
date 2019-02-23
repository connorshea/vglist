<template>
  <div class="field">
    <label class="label">{{ label }}</label>
    <div class="field" v-for="(date, platform, index) in value" :key="index">
      value: {{ value }}, platform: {{ platform }}, date: {{ date }}, index: {{ index }}
      <single-select
        v-model="platform"
        :search-path-identifier="'platforms'"
      ></single-select>
      <input type="date" class="input" v-model="value[platform]">
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
      type: Object,
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
    
  }
}
</script>
