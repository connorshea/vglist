<template>
  <div class="field">
    <label class="label">{{ label }}</label>
    <p v-if="platforms.length == 0">Add some platforms to add release dates.</p>
    <div class="field is-horizontal" v-for="(platform, index) in platforms" :key="platform['id']">
      <div class="field-label is-normal">
        <label class="label">{{ platform.name }}</label>
      </div>
      <div class="field-body">
        <div class="field">
          <p class="control">
            <input type="date" class="input" v-model="releaseDates[index]['release_date']">
          </p>
        </div>
      </div>
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
    },
    platforms: {
      type: Array,
      required: true
    }
  },
  data: function() {
    return {
      labels: {
        platforms: 'Platforms'
      },
      releaseDates: this.value
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
  }
}
</script>
