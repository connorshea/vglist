<template>
  <div>
    <a
      v-on:click="activateModal"
      class="dropdown-item has-text-danger js-merge-games-button"
      data-game-id="gameId">
      Merge
    </a>

    <merge-games-modal
      v-if="isModalActive"
      :isActive="isModalActive"
      :game="game"
      v-on:close="deactivateModal"
      v-on:closeAndRefresh="closeAndRefresh"
      v-on:create="onSubmit"
    ></merge-games-modal>
  </div>
</template>

<script lang="ts">
import MergeGamesModal from './merge-games-modal.vue';
import Rails from '@rails/ujs';
import Turbolinks from 'turbolinks';

export default {
  name: 'merge-games-button',
  components: {
    MergeGamesModal
  },
  props: {
    game: {
      type: Object,
      required: true,
      default: function() {
        return {};
      }
    }
  },
  data: function() {
    return {
      isModalActive: false
    };
  },
  methods: {
    activateModal(game = {}) {
      let html = document.querySelector('html');
      html.classList.add('is-clipped');

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
    onSubmit() {
      Turbolinks.visit(window.location.href);
    }
  }
};
</script>
