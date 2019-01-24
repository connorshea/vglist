<template>
  <div class="field">
    <label class="label">{{ label }}</label>
    <div class="control">
      <v-select
        :options="options"
        @search="onSearch"
        label="name"
        v-bind:value="platform"
      ></v-select>
    </div>
  </div>
</template>

<script>
import vSelect from 'vue-select'

export default {
  name: 'platform-select',
  components: {
    vSelect
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
      options: [],
      platform: this.value,
      platformsSearchPath: `${window.location.origin}/platforms/search.json`,
    }
  },
  methods: {
    /*
     * @param {search}  String   Current search text
     * @param {loading} Function Toggle loading class
     */
    onSearch(search, loading) {
      loading(true);
      let searchUrl = new URL(this.platformsSearchPath);
      searchUrl.searchParams.append('query', search);
      // TODO: Debounce this to prevent requests on every key press.
      // TODO: Add error handling.
      fetch(searchUrl, {
        headers: {
          "Content-Type": "application/json"
        }
      }).then((response) => {
          return response.json();
        })
        .then((platforms) => {
          this.options = platforms;
          loading(false);
        });
    }
  }
}
</script>
