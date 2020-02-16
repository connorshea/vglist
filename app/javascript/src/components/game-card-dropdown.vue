<template>
  <div class="dropdown dropdown-dynamic game-card-dropdown is-right" :class="{ 'is-active': isActive }">
    <div class="dropdown-trigger">
      <button class="button is-white" aria-haspopup="true" aria-controls="dropdown-menu" @click="onClick">
        <span class="icon" v-html="this.chevronDownIcon"></span>
      </button>
    </div>
    <div class="dropdown-menu" id="dropdown-menu" role="menu">
      <div class="dropdown-content">
        <a v-if="!favorited" class="dropdown-item" @click="favoriteGame">
          Favorite
        </a>
        <a v-else class="dropdown-item" @click="unfavoriteGame">
          Unfavorite
        </a>
      </div>
    </div>
  </div>
</template>

<script lang="ts">
import Rails from '@rails/ujs';

export default {
  name: 'game-card-dropdown',
  props: {
    gameId: {
      type: Number,
      required: true
    },
    chevronDownIcon: {
      type: String,
      required: true
    }
  },
  data: function() {
    return {
      isActive: false,
      favorited: false
    };
  },
  methods: {
    onClick(event) {
      // TODO: Figure out the best way to determine whether the game has been favorited.
      this.isActive = true;
      this.closeDropdownOnClick();
    },
    closeDropdownOnClick() {
      // Close the dropdown if the user clicks outside the dropdown.
      document.addEventListener('click', (event) => {
        // If the user is clicking on something other than an element, return early.
        if (event.target !instanceof Element && event.target !instanceof HTMLDocument) {
          return;
        }
        // If the user clicks on the dropdown itself, don't close the dropdown.
        if ((event.target as Element).closest('.dropdown-dynamic')) {
          return;
        }
        this.isActive = false;
      });
    },
    favoriteGame() {
      fetch(`games/${this.gameId}/favorite.json`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': Rails.csrfToken(),
          Accept: 'application/json'
        },
        credentials: 'same-origin'
      }).then(response => {
        if (response.ok) {
          this.favorited = true;
        }
      });
    },
    unfavoriteGame() {
      fetch(`games/${this.gameId}/unfavorite.json`, {
        method: 'DELETE',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': Rails.csrfToken(),
          Accept: 'application/json'
        },
        credentials: 'same-origin'
      }).then(response => {
        if (response.ok) {
          this.favorited = false;
        }
      });
    }
  }
};
</script>
