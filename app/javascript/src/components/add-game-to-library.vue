<template>
  <div class="is-fullwidth-mobile">
    <button
      v-if="mutableGamePurchaseExists"
      @click="editGameInLibrary()"
      class="button is-fullwidth-mobile ml-0 mr-10 mr-0-mobile"
    >Edit game in library</button>
    <button
      v-if="mutableGamePurchaseExists"
      @click="removeGameFromLibrary()"
      class="button is-fullwidth-mobile ml-0 mr-10 mr-0-mobile is-danger"
    >Remove from library</button>
    <button
      v-if="!mutableGamePurchaseExists"
      @click="addGameToLibrary()"
      class="button is-fullwidth-mobile mr-10 mr-0-mobile"
    >Add to library</button>

    <game-modal
      v-if="isModalActive"
      :isActive="isModalActive"
      :gameModalState="gameModalState"
      :userId="userId"
      v-bind="mutableGamePurchase"
      v-on:close="deactivateModal"
      v-on:closeAndRefresh="closeAndRefresh"
      v-on:create="onSubmit"
    ></game-modal>
  </div>
</template>

<script>
import GameModal from './game-modal.vue';
import Rails from 'rails-ujs';

export default {
  name: 'add-game-to-library',
  components: {
    GameModal
  },
  props: {
    userId: {
      type: Number,
      required: true
    },
    gameId: {
      type: Number,
      required: true
    },
    gamePurchaseExists: {
      type: Boolean,
      required: true
    },
    gamePurchase: {
      type: Object,
      required: false
    }
  },
  data: function() {
    return {
      mutableGamePurchaseExists: this.gamePurchaseExists,
      mutableGamePurchase: this.gamePurchase || {},
      isModalActive: false,
      gameModalState: this.mutableGamePurchaseExists
        ? 'update'
        : 'createWithGame'
    };
  },
  methods: {
    activateModal(gamePurchase) {
      let html = document.querySelector('html');
      html.classList.add('is-clipped');

      if (gamePurchase) {
        this.mutableGamePurchase = gamePurchase;
      }
      this.isModalActive = true;
    },
    deactivateModal() {
      let html = document.querySelector('html');
      html.classList.remove('is-clipped');

      this.isModalActive = false;
    },
    closeAndRefresh() {
      this.deactivateModal();
    },
    addGameToLibrary() {
      fetch(`/games/${this.gameId}.json`, {
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
        .then(game => {
          this.activateModal({ game: game });
        });
    },
    editGameInLibrary() {
      this.activateModal();
    },
    removeGameFromLibrary() {
      let removeGameFromLibraryPath = `/games/${
        this.gameId
      }/remove_game_from_library`;

      fetch(removeGameFromLibraryPath, {
        method: 'DELETE',
        headers: {
          'X-CSRF-Token': Rails.csrfToken(),
          Accept: 'application/json'
        },
        credentials: 'same-origin'
      }).then(response => {
        if (response.ok) {
          this.mutableGamePurchaseExists = false;
        }
      });
    },
    onSubmit(gamePurchase) {
      this.mutableGamePurchaseExists = true;
      this.mutableGamePurchase = gamePurchase;
    }
  }
};
</script>
