<template>
  <div class="is-fullwidth">
    <button
      v-if="gamePurchaseExists"
      @click="editGameInLibrary()"
      class="button is-fullwidth is-primary mr-5 mr-0-mobile"
    >
      <span class="icon" v-html="pencilIcon"></span>
      <span>Edit game in library</span>
    </button>
    <button
      v-if="gamePurchaseExists"
      @click="removeGameFromLibrary()"
      class="button is-fullwidth is-danger mr-5 mr-0-mobile mt-10"
    >
      <span class="icon" v-html="removeIcon"></span>
      <span>Remove from library</span>
    </button>
    <button
      v-if="!gamePurchaseExists"
      @click="addGameToLibrary()"
      class="button is-fullwidth is-primary mr-5 mr-0-mobile"
    >
      <span class="icon" v-html="plusIcon"></span>
      <span>Add to library</span>
    </button>

    <game-modal
      v-if="isModalActive"
      :isActive="isModalActive"
      :gameModalState="gameModalState"
      :userId="userId"
      v-bind="mutableGamePurchase"
      @close="deactivateModal"
      @closeAndRefresh="closeAndRefresh"
      @create="onSubmit"
    />
  </div>
</template>

<script setup lang="ts">
import GameModal from './game-modal.vue';
import Rails from '@rails/ujs';
import Turbolinks from 'turbolinks';
import { ref, computed, onMounted } from 'vue';

interface Props {
  userId: number;
  gameId: number;
  gamePurchaseExists: boolean;
  gamePurchaseId?: number;
  pencilIcon: string;
  plusIcon: string;
  removeIcon: string;
}

const props = defineProps<Props>();

// Reactive data
const mutableGamePurchase = ref<any>({});
const isModalActive = ref(false);
const gameModalState = computed(() => props.gamePurchaseExists ? 'update' : 'createWithGame');

// Methods
function activateModal(game: any = {}) {
  let html = document.querySelector('html');
  html!.classList.add('is-clipped');

  if (Object.keys(mutableGamePurchase.value).length === 0) {
    mutableGamePurchase.value = { game: game };
  }
  isModalActive.value = true;
}

function deactivateModal() {
  let html = document.querySelector('html');
  html!.classList.remove('is-clipped');

  isModalActive.value = false;
}

function closeAndRefresh() {
  deactivateModal();
}

function addGameToLibrary() {
  fetch(`/games/${props.gameId}.json`, {
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
      activateModal(game);
    });
}

function editGameInLibrary() {
  activateModal();
}

function removeGameFromLibrary() {
  let removeGameFromLibraryPath = `/games/${props.gameId}/remove_game_from_library`;

  const headers: HeadersInit = {
    Accept: 'application/json',
    'X-CSRF-Token': Rails.csrfToken()!
  };


  fetch(removeGameFromLibraryPath, {
    method: 'DELETE',
    headers,
    credentials: 'same-origin'
  }).then(response => {
    if (response.ok) {
      Turbolinks.visit(window.location.href);
    }
  });
}

function onSubmit() {
  Turbolinks.visit(window.location.href);
}

// Lifecycle
onMounted(() => {
  if (props.gamePurchaseId) {
    fetch(`/game_purchases/${props.gamePurchaseId}.json`, {
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
        mutableGamePurchase.value = gamePurchase;
      });
  }
});
</script>
