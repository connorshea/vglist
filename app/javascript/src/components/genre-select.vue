<template>
  <v-select
    multiple
    :options="options"
    @search="onSearch"
    label="name"
  ></v-select>
</template>

<script>
import vSelect from 'vue-select'

export default {
  components: {
    vSelect
  },
  props: {
    genresPath: {
      type: String,
      required: true
    }
  },
  data: function() {
    return {
      options: []
    }
  },
  methods: {
    /*
     * @param {search}  String   Current search text
     * @param {loading} Function Toggle loading class
     */
    onSearch(search, loading) {
      loading(true);
      // TODO: Debounce this to prevent requests on every key press.
      fetch(this.genresPath)
        .then((response) => {
          return response.json();
        })
        .then((genres) => {
          this.options = genres;
          loading(false);
        });
    }
  }
}
</script>

