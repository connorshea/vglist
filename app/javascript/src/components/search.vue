<template>
  <div class="navbar-item has-dropdown field mt-10" v-bind:class="{ 'is-active': dropdownActive }">
    <p class="control">
      <input
        v-model="query"
        @input="onSearch"
        class="input"
        type="search"
        placeholder="Search">
    </p>

    <div class="navbar-dropdown">
      <a
        v-for="result in this.betterSearchResults"
        :key="result.id"
        :href="result.url"
        class="navbar-item">
          {{ result.content }}
      </a>
    </div>
  </div>
</template>

<script>
export default {
  data: function() {
    return {
      searchUrl: '/search.json',
      query: '',
      searchResults: []
    }
  },
  methods: {
    onSearch() {
      if (this.query.length > 2) {
        fetch(`${this.searchUrl}?query=${this.query}`)
          .then((response) => {
            return response.json();
          })
          .then((searchResults) => {
            this.searchResults = searchResults;
          });
      }
    }
  },
  computed: {
    // Determine if the dropdown is active so we can display it when it is.
    dropdownActive: function () {
      return this.searchResults.length > 0;
    },
    betterSearchResults: function() {
      let plurals = {
        'Company': 'companies',
        'Engine': 'engines',
        'Game': 'games',
        'Genre': 'genres',
        'Platform': 'platforms',
        'Series': 'series'
      }

      return this.searchResults.map(function(result) {
        result.url = `/${plurals[result.searchable_type]}/${result.searchable_id}`;
        return result;
      });
    }
  }
}
</script>

