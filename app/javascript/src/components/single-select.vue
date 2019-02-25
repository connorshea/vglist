<template>
  <div>
    <label v-if="label" class="label">{{ label }}</label>
    <div class="control">
      <v-select
        :options="options"
        @search="onSearch"
        label="name"
        v-bind:value="value"
      ></v-select>
    </div>
  </div>
</template>

<script>
import vSelect from 'vue-select'

export default {
  name: 'single-select',
  components: {
    vSelect
  },
  props: {
    label: {
      type: String,
      required: false
    },
    value: {
      type: Object,
      required: true
    },
    searchPathIdentifier: {
      type: String,
      required: true
    }
  },
  data: function() {
    return {
      options: [],
      searchPath: `${window.location.origin}/${this.searchPathIdentifier}/search.json`,
    }
  },
  methods: {
    /*
     * @param {search}  String   Current search text
     * @param {loading} Function Toggle loading class
     */
    onSearch(search, loading) {
      loading(true);
      let searchUrl = new URL(this.searchPath);
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
        .then((items) => {
          this.options = items;
          loading(false);
        });
    }
  }
}
</script>
