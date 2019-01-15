<template>
  <v-select
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
    onSearch(search, loading) {
      loading(true);
      console.log(this);
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

