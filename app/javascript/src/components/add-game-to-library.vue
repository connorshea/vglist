<template>
  <div>
    <button
      v-if="gamePurchaseExists"
      class="button is-fullwidth-mobile is-danger"
    >Remove from library</button>
    <button
      v-else
      @click="loadModal()"
      class="button is-fullwidth-mobile mr-5 mr-0-mobile"
    >Add to library</button>
    <!-- TODO: Add an edit button when the game already exists. -->

    <game-modal
      v-if="isModalActive"
      :isActive="isModalActive"
      :create="create"
      :userId="userId"
      v-bind="currentGame"
      v-on:close="deactivateModal"
      v-on:closeAndRefresh="closeAndRefresh"
      v-on:create="todoMethod"
    ></game-modal>
  </div>
</template>

<script>
import GameModal from './game-modal.vue';

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
    }
  },
  data: function() {
    return {
      isModalActive: false,
      currentGame: {},
      create: !this.gamePurchaseExists
    };
  },
  methods: {
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
    },
    closeAndRefresh() {
      this.deactivateModal();
    },
    loadModal() {
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
          this.activateModal({ game });
        });
    },
    todoMethod() {
      console.log('todo');
    },
    removeGameFromLibrary() {
      let removeGameFromLibraryPath = `/games/${
        this.gameId
      }/remove_game_from_library`;

      let params = {
        id: this.gameId
      };
    }
  }
};
</script>
