<template>
  <div class="is-fullwidth">
    <button
      v-if="gamePurchaseExists"
      @click="editGameInLibrary()"
      class="button is-fullwidth is-primary mr-5 mr-0-mobile"
    >
      <span class="icon" v-html="this.pencilIcon"></span>
      <span>Edit game in library</span>
    </button>
    <button
      v-if="gamePurchaseExists"
      @click="removeGameFromLibrary()"
      class="button is-fullwidth is-danger mr-5 mr-0-mobile"
    >
      <span class="icon" v-html="this.removeIcon"></span>
      <span>Remove from library</span>
    </button>
    <button
      v-if="!gamePurchaseExists"
      @click="addGameToLibrary()"
      class="button is-fullwidth is-primary mr-5 mr-0-mobile"
    >
      <span class="icon" v-html="this.plusIcon"></span>
      <span>Add to library</span>
    </button>

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

<script lang="ts">
import GameModal from './game-modal.vue';
import Rails from '@rails/ujs';
import Turbolinks from 'turbolinks';

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
    gamePurchaseId: {
      type: Number,
      required: false
    },
    pencilIcon: {
      type: String,
      required: true
    },
    plusIcon: {
      type: String,
      required: true
    },
    removeIcon: {
      type: String,
      required: true
    }
  },
  data: function() {
    return {
      mutableGamePurchase: {},
      isModalActive: false,
      gameModalState: this.gamePurchaseExists ? 'update' : 'createWithGame'
    };
  },
  methods: {
    activateModal(game = {}) {
      let html = document.querySelector('html');
      html.classList.add('is-clipped');

      if (Object.keys(this.mutableGamePurchase).length === 0) {
        this.mutableGamePurchase = { game: game };
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
          this.activateModal(game);
        });
    },
    editGameInLibrary() {
      this.activateModal();
    },
    removeGameFromLibrary() {
      let removeGameFromLibraryPath = `/games/${this.gameId}/remove_game_from_library`;

      fetch(removeGameFromLibraryPath, {
        method: 'DELETE',
        headers: {
          'X-CSRF-Token': Rails.csrfToken(),
          Accept: 'application/json'
        },
        credentials: 'same-origin'
      }).then(response => {
        if (response.ok) {
          Turbolinks.visit(window.location.href);
        }
      });
    },
    onSubmit() {
      Turbolinks.visit(window.location.href);
    }
  },
  created: function() {
    if (this.gamePurchaseId) {
      fetch(`/game_purchases/${this.gamePurchaseId}.json`, {
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
        .then(gamePurchase => {
          this.mutableGamePurchase = gamePurchase;
        });
    }
  }
};
</script>
