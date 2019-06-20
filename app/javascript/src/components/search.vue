<template>
  <div class="navbar-item has-dropdown field mt-10" v-bind:class="{ 'is-active': dropdownActive }">
    <p class="control">
      <input
        v-model="query"
        @input="onSearch"
        @keyup.up.prevent="onUpArrow"
        @keyup.down.prevent="onDownArrow"
        @keyup.enter.prevent="onEnter"
        class="input"
        type="search"
        placeholder="Search"
      >
    </p>

    <div v-if="dropdownActive" class="navbar-search-dropdown navbar-dropdown">
      <p class="navbar-item" v-if="!hasSearchResults">No results.</p>
      <div v-for="(type, index) in Object.keys(betterSearchResults)" :key="type">
        <hr v-if="index > 0" class="navbar-divider">
        <p class="navbar-item navbar-dropdown-header">{{ capitalizedPlurals[type] }}</p>
        <a
          v-for="result in betterSearchResults[type]"
          :key="result.id"
          :href="result.url"
          class="navbar-item"
          :class="{
            'is-active':
              activeSearchResult !== -1 &&
              flattenedSearchResults[activeSearchResult].searchable_id ===
                result.searchable_id
          }"
        >{{ result.content }}</a>
      </div>
    </div>
  </div>
</template>

<script lang="ts">
export default {
  data: function() {
    return {
      searchUrl: '/search.json',
      query: '',
      searchResults: {},
      plurals: {
        Game: 'games',
        Series: 'series',
        Company: 'companies',
        Platform: 'platforms',
        Engine: 'engines',
        Genre: 'genres'
      },
      activeSearchResult: -1
    };
  },
  methods: {
    // Debounce the search for 400ms before showing results, to prevent
    // searching from sending a ton of requests.
    onSearch: _.debounce(function(e) {
      if (this.query.length > 1) {
        fetch(`${this.searchUrl}?query=${this.query}`)
          .then(response => {
            return response.json();
          })
          .then(searchResults => {
            this.searchResults = searchResults;
            this.activeSearchResult = -1;
          });
      }
    }, 400),
    onUpArrow() {
      if (this.activeSearchResult >= 0) {
        this.activeSearchResult = this.activeSearchResult - 1;
        this.scrollToActiveItem();
      }
    },
    onDownArrow() {
      if (this.activeSearchResult < this.flattenedSearchResults.length - 1) {
        this.activeSearchResult = this.activeSearchResult + 1;
        this.scrollToActiveItem();
      }
    },
    // On enter, have turbolinks navigate to the active item's linked page.
    onEnter() {
      let activeItem = document.querySelector(
        '.navbar-search-dropdown .navbar-item.is-active'
      );
      if (activeItem !== null) {
        Turbolinks.visit(activeItem.href);
      }
    },
    scrollToActiveItem() {
      // Select the current active item and the searchDropdown.
      let activeItem = document.querySelector(
        '.navbar-search-dropdown .navbar-item.is-active'
      );
      let searchDropdown = document.querySelector('.navbar-search-dropdown');
      // If the activeItem exists, scroll to it as the user moves through the dropdown options.
      if (activeItem !== null) {
        searchDropdown.scrollTop =
          activeItem.offsetTop - searchDropdown.offsetTop;
      }
    }
  },
  computed: {
    // Determine if the dropdown is active so we can display it when it is.
    dropdownActive: function() {
      return this.query.length > 1;
    },
    hasSearchResults: function() {
      return Object.values(this.searchResults).flat().length != 0;
    },
    // Do a stupid hack to capitalize the first letter of each plural value,
    // e.g. "Games", "Companies", etc.
    capitalizedPlurals: function() {
      let capitalizedPluralEntries = Object.entries(this.plurals).map(type => {
        type[1] = type[1].charAt(0).toUpperCase() + type[1].slice(1);
        return type;
      });

      return Object.fromEntries(capitalizedPluralEntries);
    },
    betterSearchResults: function() {
      let betterSearchResults = this.searchResults;
      Object.keys(betterSearchResults).forEach(key => {
        if (betterSearchResults[key].length == 0) {
          delete betterSearchResults[key];
          return true;
        }
        betterSearchResults[key].map(result => {
          result.url = `/${this.plurals[result.searchable_type]}/${
            result.searchable_id
          }`;
          return result;
        });
      });

      return betterSearchResults;
    },
    flattenedSearchResults: function() {
      return Object.values(this.searchResults).flat();
    }
  }
};
</script>
