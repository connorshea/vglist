<template>
  <div class="field">
    <label class="label">{{ label }}</label>
    <div class="control">
      <v-select
        :options="options"
        @search="onSearch"
        label="name"
        v-bind:value="game"
      ></v-select>
    </div>
  </div>
</template>

<script>
import vSelect from 'vue-select'

export default {
  name: 'game-select',
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
      game: this.value,
      gamesSearchPath: `${window.location.origin}/games/search.json`,
    }
  },
  methods: {
    /*
     * @param {search}  String   Current search text
     * @param {loading} Function Toggle loading class
     */
    onSearch(search, loading) {
      loading(true);
      let searchUrl = new URL(this.gamesSearchPath);
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
        .then((games) => {
          this.options = games;
          loading(false);
        });
    }
  }
}
</script>
