<template>
  <div class="modal" :class="{ 'is-active': isActive }">
    <div @click="onClose" class="modal-background"></div>
    <div class="modal-card">
      <header class="modal-card-head">
        <p class="modal-card-title">{{ `Merge ${game.name} into another game` }}</p>
        <button @click="onClose" class="delete" aria-label="close"></button>
      </header>
      <section class="modal-card-body modal-card-body-allow-overflow">
        <!-- Display errors if there are any. -->
        <div class="notification errors-notification is-danger" v-if="errors.length > 0">
          <p>
            {{ errors.length > 1 ? 'Errors' : 'An error' }} prevented this game from
            being merged:
          </p>
          <ul>
            <li v-for="error in errors" :key="error">{{ error }}</li>
          </ul>
        </div>
        <div>
          <single-select
            :label="'Game'"
            v-model="gameA"
            :search-path-identifier="'games'"
            :max-height="'150px'"
            @input="selectGame"
          ></single-select>
        </div>
      </section>
      <footer class="modal-card-foot">
        <button @click="onSave" class="button is-primary js-submit-button" :disabled="!this.gameSelected">Submit</button>
        <button @click="onClose" class="button">Cancel</button>
      </footer>
    </div>
  </div>
</template>

<script lang="ts">
import SingleSelect from './fields/single-select.vue';
import VglistUtils from '../utils';
import Turbolinks from 'turbolinks';

export default {
  name: 'merge-games-modal',
  components: {
    SingleSelect
  },
  props: {
    game: {
      type: Object,
      required: true,
      default: function() {
        return {};
      }
    },
    isActive: {
      type: Boolean,
      required: true
    }
  },
  data() {
    return {
      errors: [],
      gameSelected: false,
      gameA: null
    };
  },
  methods: {
    onClose() {
      this.$emit('close');
    },
    onSave() {
      let gameAId = this.gameA.id;
      let gameBId = this.game.id;
      let mergePath = `/games/${gameAId}/merge/${gameBId}.json`;
      VglistUtils.rawAuthenticatedFetch(
        mergePath,
        'POST'
      ).then(response => {
        // HTTP 301 response
        if (response.redirected) {
          Turbolinks.clearCache();
          Turbolinks.visit(response.url);
        // If it's not a redirect, check it for errors and display them.
        } else {
          response.json().then(json => {
            this.errors = json.errors
          });
          let submitButton = document.querySelector('.js-submit-button');
          submitButton.classList.add('js-submit-button-error');
          setTimeout(() => {
            submitButton.classList.remove('js-submit-button-error');
          }, 2000);
        }
      });
    },
    selectGame() {
      this.gameSelected = true;
    }
  }
};
</script>
