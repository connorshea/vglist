<template>
  <div class="field">
    <label class="label">{{ label }}</label>
    <div class="control">
      <v-select
        multiple
        :options="options"
        @search="onSearch"
        label="name"
        v-bind:value="engines"
      ></v-select>
    </div>
  </div>
</template>

<script>
import vSelect from 'vue-select'

export default {
  name: 'engine-select',
  components: {
    vSelect
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
      options: [],
      engines: this.value,
      enginesSearchPath: `${window.location.origin}/engines/search.json`,
    }
  },
  methods: {
    /*
     * @param {search}  String   Current search text
     * @param {loading} Function Toggle loading class
     */
    onSearch(search, loading) {
      loading(true);
      let searchUrl = new URL(this.enginesSearchPath);
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
        .then((engines) => {
          this.options = engines;
          loading(false);
        });
    }
  }
}
</script>
