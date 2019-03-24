<template>
  <div class="game-library">
    <div v-if="!libraryEmpty" class="columns game-library-header game-library-row">
      <div class="column game-name">Game</div>
      <div class="column game-rating">Rating</div>
      <div class="column game-hours-played">Hours Played</div>
      <div class="column game-completion-status">Completion Status</div>
      <div class="column game-start-and-completion-dates">Start/Completion Dates</div>
      <div class="column game-platforms">Platforms</div>
      <div class="column game-comments">Comments</div>
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
      Add a game to your library
    </button>

    <game-modal
      v-if="isModalActive"
      :isActive="isModalActive"
      :create="doesGamePurchaseExist"
      :userId="userId"
      v-bind="currentGame"
      v-on:close="deactivateModal"
      v-on:closeAndRefresh="closeAndRefresh"
      v-on:create="refreshLibrary"
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
    },
    userId: {
      type: Number,
      required: true
    }
  },
  data: function() {
    return {
      purchasedGames: [],
      isModalActive: false,
      currentGame: {},
      doesGamePurchaseExist: false
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
      if (!this.isEditable) { return; }
      let html = document.querySelector('html');
      html.classList.add('is-clipped');

      this.doesGamePurchaseExist = Object.entries(game).length > 0 ? false : true;
      this.currentGame = game;
      this.isModalActive = true;
    },
    deactivateModal() {
      let html = document.querySelector('html');
      html.classList.remove('is-clipped');

      this.isModalActive = false;
    },
    closeAndRefresh() {
      this.deactivateModal();
      // Give it some time for the change to persist on the backend.
      setTimeout(() => {
        this.refreshLibrary();
      }, 750);
    }
  },
  computed: {
    libraryEmpty: function() {
      return this.purchasedGames.length === 0;
    }
  }
}
</script>

