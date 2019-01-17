<template>
  <div class="field">
    <label class="label">{{ label }}</label>
    <div class="control">
      <v-select
        multiple
        :options="options"
        @search="onSearch"
        label="name"
        v-bind:value="genres"
      ></v-select>
    </div>
  </div>
</template>

<script>
import vSelect from 'vue-select'

export default {
  name: 'genre-select',
  components: {
    vSelect
  },
  props: {
    genresPath: {
      type: String,
      required: true
    },
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
      genres: this.value
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
