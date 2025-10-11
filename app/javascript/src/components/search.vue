<template>
  <div class="navbar-item has-dropdown field mt-10 mx-10" v-bind:class="{ 'is-active': dropdownActive }">
    <div class="control">
      <div class="field mb-0">
        <p class="control has-icons-left">
          <input
            v-model="query"
            @input="onSearch"
            @keyup.up.prevent="onUpArrow"
            @keyup.down.prevent="onDownArrow"
            @keyup.enter.prevent="onEnter"
            class="input navbar-search-input"
            type="search"
            placeholder="Search"
          />
          <span class="icon is-small is-left" v-html="searchIcon"></span>
        </p>
      </div>
    </div>

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
          }">
          <div class="media">
            <figure class="media-left image is-48x48" v-if="type === 'Game' || type === 'User'">
              <img :src="result.image_url" width='48px' height='48px' class="game-cover">
            </figure>
            <div class="media-content">
              <p v-if="type === 'Game'" class="has-text-weight-semibold">{{ result.content }}</p>
              <p v-else>{{ result.content }}</p>
              <p v-if="type === 'Game'">
                <!-- Outputs "2009 · Nintendo", "Nintendo", or "2009" depending on what data it has. -->
                {{ [
                    result.release_date === null ? '' : result.release_date.slice(0, 4),
                    result.developer === null ? '' : result.developer
                  ].filter(x => x !== '').join(' · ') }}
              </p>
            </div>
          </div>
        </a>
        <!-- If there are a multiple of 15 games, we can potentially load another page of them. -->
        <a class="navbar-item"
           v-if="type === 'Game' && betterSearchResults[type].length % 15 === 0 && !moreAlreadyLoaded"
           @click="onMoreGames"
        >
          <div class="media">
            <div class="media-content">
              <p>More...</p>
            </div>
          </div>
        </a>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted } from 'vue';
import Turbolinks from 'turbolinks';
import { debounce } from 'lodash-es';

interface Props {
  searchIcon: string;
  searchParam?: string;
}

const props = withDefaults(defineProps<Props>(), {
  searchParam: ''
});

const searchUrl = '/search.json';
const query = ref(props.searchParam);
const searchResults = ref<Record<string, any>>({});
const plurals = {
  Game: 'games',
  Series: 'series',
  Company: 'companies',
  Platform: 'platforms',
  Engine: 'engines',
  Genre: 'genres',
  User: 'users'
};
const activeSearchResult = ref(-1);
const currentPage = ref(1);
const moreAlreadyLoaded = ref(false);

onMounted(() => {
  if (props.searchParam.length > 0) {
    onSearch();
  }
});

// Debounce the search for 400ms before showing results, to prevent
// searching from sending a ton of requests.
const onSearch = debounce(() => {
  if (query.value.length > 1) {
    fetch(`${searchUrl}?query=${query.value}`)
      .then(response => {
        return response.json();
      })
      .then(results => {
        searchResults.value = results;
        activeSearchResult.value = -1;
      });
  }
}, 400);

function onUpArrow() {
  if (activeSearchResult.value >= 0) {
    activeSearchResult.value = activeSearchResult.value - 1;
    scrollToActiveItem();
  }
}

function onDownArrow() {
  if (activeSearchResult.value < flattenedSearchResults.value.length - 1) {
    activeSearchResult.value = activeSearchResult.value + 1;
    scrollToActiveItem();
  }
}

// On enter, have turbolinks navigate to the active item's linked page.
function onEnter() {
  const activeItem: HTMLLinkElement | null = document.querySelector(
    '.navbar-search-dropdown .navbar-item.is-active'
  );
  if (activeItem !== null) {
    Turbolinks.visit(activeItem.href);
  }
}

function scrollToActiveItem() {
  // Select the current active item and the searchDropdown.
  const activeItem: HTMLElement | null = document.querySelector(
    '.navbar-search-dropdown .navbar-item.is-active'
  );
  const searchDropdown: HTMLElement | null = document.querySelector(
    '.navbar-search-dropdown'
  );
  // If the activeItem exists, scroll to it as the user moves through the dropdown options.
  if (activeItem !== null && searchDropdown !== null) {
    searchDropdown.scrollTop =
      activeItem.offsetTop - searchDropdown.offsetTop;
  }
}

// Load more games if the user selects "More...".
function onMoreGames() {
  currentPage.value += 1;
  fetch(`${searchUrl}?query=${query.value}&page=${currentPage.value}&only_games=true`)
      .then(response => {
        return response.json();
      })
      .then(results => {
        searchResults.value['Game'] = searchResults.value['Game'].concat(results['Game']);
        activeSearchResult.value = -1;
        // If there are a multiple of 15 results and no new games are
        // added, the component will still show a "More..." button. This
        // sets 'moreAlreadyLoaded' to true to make sure the 'More...'
        // button is hidden and handle this edge case.
        if (results['Game'].length === 0) {
          moreAlreadyLoaded.value = true;
        }
      });
}

// Determine if the dropdown is active so we can display it when it is.
const dropdownActive = computed(() => {
  return query.value.length > 1;
});

const hasSearchResults = computed(() => {
  return Object.values(searchResults.value).flat().length != 0;
});

// Do a stupid hack to capitalize the first letter of each plural value,
// e.g. "Games", "Companies", etc.
const capitalizedPlurals = computed(() => {
  const capitalizedPluralEntries = Object.entries(plurals).map(
    (type: Array<any>) => {
      type[1] = type[1].charAt(0).toUpperCase() + type[1].slice(1);
      return type;
    }
  );

  return Object.fromEntries(capitalizedPluralEntries);
});

const betterSearchResults = computed(() => {
  const betterResults = { ...searchResults.value };
  Object.keys(betterResults).forEach(key => {
    if (betterResults[key].length == 0) {
      delete betterResults[key];
      return true;
    }
    betterResults[key].map((result: any) => {
      // Use the slug in the URL if it's a user.
      const url_key = result.searchable_type === 'User' ? result.slug : result.searchable_id;
      result.url = `/${plurals[result.searchable_type as keyof typeof plurals]}/${url_key}`;
      return result;
    });
  });

  return betterResults;
});

const flattenedSearchResults = computed(() => {
  return Object.values(searchResults.value).flat();
});
</script>
