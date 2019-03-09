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
        v-for="result in this.searchResults"
        :key="result.id"
        :href="'/games/' + result.searchable_id"
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
    }
  }
}
</script>

