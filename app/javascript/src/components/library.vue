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
      v-on:edit="activateModal"
    ></game-in-library>

    <p v-if="libraryEmpty">This library is empty.</p>

    <button
      v-if="isEditable"
      @click="activateModal({})"
      class="button mt-10">
      Add a game to your library.
    </button>

    <game-modal
      v-if="isEditable"
      :isActive="isModalActive"
      :gamePurchase="currentGame"
      v-on:close="deactivateModal"
    ></game-modal>
  </div>
</template>

<script>
import GameInLibrary from './game-in-library.vue';
import GameModal from './game-modal.vue';

export default {
  components: {
    GameInLibrary,
    GameModal
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
      purchasedGames: [],
      isModalActive: false,
      currentGame: {}
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
    },
    activateModal(game = {}) {
      let html = document.querySelector('html');
      html.classList.add('is-clipped');

      this.currentGame = game;
      this.isModalActive = true;
    },
    deactivateModal() {
      let html = document.querySelector('html');
      html.classList.remove('is-clipped');

      this.isModalActive = false;
    }
  },
  computed: {
    libraryEmpty: function() {
      return this.purchasedGames.length === 0;
    }
  }
}
</script>

