<template>
  <div class="game-library">
    <library-table
      :rows="games"
      :isEditable="isEditable"
      :gamePurchasesUrl="gamePurchasesUrl"
      :isLoading="isLoading"
      @loaded="libraryLoaded"
      @edit="activateModal"
      @delete="refreshLibrary"
      @addGame="activateModal({})"
    ></library-table>

    <game-modal
      v-if="isModalActive"
      :isActive="isModalActive"
      :gameModalState="gameModalState"
      :userId="userId"
      v-bind="currentGame"
      v-on:close="deactivateModal"
      v-on:closeAndRefresh="closeAndRefresh"
      v-on:create="refreshLibrary"
    ></game-modal>
  </div>
</template>

<script>
import LibraryTable from './library-table.vue';
import GameModal from './game-modal.vue';

export default {
  components: {
    LibraryTable,
    GameModal
  },
  props: {
    gamePurchasesUrl: {
      type: String,
      required: true
    },
    userId: {
      type: Number,
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
      isModalActive: false,
      currentGame: {},
      doesGamePurchaseExist: false,
      games: [],
      isLoading: true
    };
  },
  created: function() {
    this.loadGames();
  },
  methods: {
    loadGames() {
      fetch(this.gamePurchasesUrl, {
        headers: {
          'Content-Type': 'application/json'
        }
      })
        .then(response => {
          return response.json().then(json => {
            if (response.ok) {
              return Promise.resolve(json);
            }
            return Promise.reject(json);
          });
        })
        .then(purchasedGames => {
          this.games = purchasedGames;
          this.isLoading = false;
          // Emit a bulma init event to make sure that the filter dropdown is initialized.
          let event = new Event('bulma:init');
          document.body.dispatchEvent(event);
        });
    },
    refreshLibrary() {
      this.loadGames();
    },
    activateModal(game = {}) {
      if (!this.isEditable) {
        return;
      }
      let html = document.querySelector('html');
      html.classList.add('is-clipped');

      this.doesGamePurchaseExist =
        Object.entries(game).length > 0 ? false : true;
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
    },
    libraryLoaded() {
      this.isLoading = false;
    }
  },
  computed: {
    gameModalState: function() {
      let currentGameExists = Object.keys(this.currentGame).length > 0;
      return currentGameExists ? 'update' : 'create';
    }
  }
};
</script>
