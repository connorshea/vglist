<template>
  <div class="field">
    <label class="label">{{ label }}</label>
    <div class="field" v-for="(releaseDate,i) in value" :key="releaseDate.id">
      <single-select
        v-model="value[i].key"
        :search-path-identifier="'platforms'"
      ></single-select>
      <input type="date" class="input" v-model="value[i].value">
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
    
  }
}
</script>
