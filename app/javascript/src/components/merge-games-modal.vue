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
            @update:modelValue="selectGame"
            :customOptionFunc="customOptionLabel"
          ></single-select>
        </div>
      </section>
      <footer class="modal-card-foot">
        <button @click="onSave" class="button is-primary js-submit-button" :disabled="!gameSelected">Submit</button>
        <button @click="onClose" class="button ml-10">Cancel</button>
      </footer>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref } from 'vue';
import SingleSelect from './fields/single-select.vue';
import VglistUtils from '../utils';
import Turbolinks from 'turbolinks';

interface Props {
  game: Record<string, any>;
  isActive: boolean;
}

// TODO: replace withDefaults after Vue 3.5 upgrade.
// https://vuejs.org/guide/components/props.html#reactive-props-destructure
const props = withDefaults(defineProps<Props>(), {
  game: () => ({})
});

const emit = defineEmits(['close', 'save']);

const errors = ref<string[]>([]);
const gameSelected = ref(false);
const gameA = ref<Record<string, any> | undefined>(undefined);

function onClose() {
  emit('close');
}

function onSave() {
  const gameAId = gameA.value?.id;
  const gameBId = props.game.id;
  const mergePath = `/games/${gameAId}/merge/${gameBId}.json`;
  
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
        errors.value = json.errors;
      });
      const submitButton = document.querySelector('.js-submit-button');
      if (submitButton) {
        submitButton.classList.add('js-submit-button-error');
        setTimeout(() => {
          submitButton.classList.remove('js-submit-button-error');
        }, 2000);
      }
    }
  });
}

function selectGame() {
  gameSelected.value = true;
}

// Include the vglist ID in the dropdown to help distinguish between games
// that have the same name.
// TODO: May need to fix this for the new select library.
function customOptionLabel(item: Record<string, any>) {
  item.name = `${item.name} (${item.id})`;
  return item;
}
</script>
