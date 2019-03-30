<template>
  <div class="field">
    <label class="label">{{ label }}</label>
    <div class="control">
      <v-select
        multiple
        :options="options"
        @search="onSearch"
        label="name"
        @change="onChange"
        v-bind:value="value"
      ></v-select>
    </div>
  </div>
</template>

<script>
import vSelect from 'vue-select';

export default {
  name: 'multi-select',
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
    },
    onChange(selectedItems) {
      this.$emit('input', selectedItems)
    }
  }
}
</script>
