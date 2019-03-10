<template>
  <div class="game-library">
    <div v-if="!libraryEmpty" class="columns game-library-header game-library-row">
      <div class="column game-name">Game</div>
      <div class="column game-score">Score</div>
      <div class="column game-comment">Comment</div>
      <div v-if="isEditable" class="column game-actions">Actions</div>
    </div>
    <game-in-library
      v-for="gameInLibrary in purchasedGames"
      :key="gameInLibrary.id"
      :gameInLibrary="gameInLibrary"
      :isEditable="isEditable"
      v-on:delete="refreshLibrary"
    ></game-in-library>

    <p v-if="libraryEmpty">This library is empty.</p>

    <button v-if="isEditable" class="button mt-10">
      Add a game to your library.
    </button>
  </div>
</template>

<script>
import GameInLibrary from './game-in-library.vue';

export default {
  components: {
    GameInLibrary
  },
  props: {
    gamePurchasesUrl: {
      type: String,
      required: true
    },
    isEditable: {
      type: Boolean,
      required: false,
      default: false
    }
  },
  data: function() {
    return {
      purchasedGames: []
    }
  },
  created: function() {
    fetch(this.gamePurchasesUrl, {
      headers: {
        "Content-Type": "application/json"
      }
    }).then((response) => {
      return response.json().then((json) => {
        if (response.ok) {
          return Promise.resolve(json);
        }
        return Promise.reject(json);
      });
    }).then((purchasedGames) => {
      this.purchasedGames = purchasedGames;
    });
  },
  methods: {
    refreshLibrary() {
      fetch(this.gamePurchasesUrl, {
        headers: {
          "Content-Type": "application/json"
        }
      }).then((response) => {
        return response.json().then((json) => {
          if (response.ok) {
            return Promise.resolve(json);
          }
          return Promise.reject(json);
        });
      }).then((purchasedGames) => {
        this.purchasedGames = purchasedGames;
      });
    }
  },
  computed: {
    libraryEmpty: function() {
      return this.purchasedGames.length === 0;
    }
  }
}
</script>

