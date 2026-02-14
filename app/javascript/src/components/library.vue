<template>
  <div class="game-library">
    <library-edit-bar
      v-if="isEditBarActive"
      :gamePurchases="selectedGamePurchases"
      @closeEditBar="closeEditBar"
    ></library-edit-bar>

    <library-table
      :rows="games"
      :isEditable="isEditable"
      :isLoading="isLoading"
      :chevronDownIcon="chevronDownIcon"
      @edit="activateModal"
      @delete="refreshLibrary"
      @addGame="activateModal({})"
      @selectedGamePurchasesChanged="selectedGamePurchasesChanged"
    ></library-table>

    <game-modal
      v-if="isModalActive"
      :isActive="isModalActive"
      :gameModalState="gameModalState"
      :userId="userId"
      v-bind="currentGame"
      @close="deactivateModal"
      @closeAndRefresh="closeAndRefresh"
      @create="refreshLibrary"
    ></game-modal>
  </div>
</template>

<script setup lang="ts">
import LibraryTable from "./library-table.vue";
import GameModal from "./game-modal.vue";
import LibraryEditBar from "./library-edit-bar.vue";
import { ref, computed, onMounted } from "vue";

interface Props {
  gamePurchasesUrl: string;
  userId: number;
  isEditable?: boolean;
  chevronDownIcon: string;
}

const props = withDefaults(defineProps<Props>(), {
  isEditable: false,
});

// Reactive data
const isModalActive = ref(false);
const isEditBarActive = ref(false);
const selectedGamePurchases = ref<any[]>([]);
const currentGame = ref<any>({});
const doesGamePurchaseExist = ref(false);
const games = ref<any[]>([]);
const isLoading = ref(true);

// Methods
function loadGames(): void {
  fetch(props.gamePurchasesUrl, {
    headers: {
      "Content-Type": "application/json",
    },
  })
    .then((response) => {
      return response.json().then((json) => {
        if (response.ok) {
          return Promise.resolve(json);
        }
        return Promise.reject(json);
      });
    })
    .then((purchasedGames) => {
      games.value = purchasedGames;
      isLoading.value = false;

      // Make sure to trigger bulma:init, even if the load event has already fired.
      // This can theoretically trigger a race condtion because readyState
      // will be set to complete right before the load event is fired, but yolo.
      if (document.readyState === "complete") {
        // Emit a bulma init event to make sure that the filter dropdown is initialized.
        let event = new Event("bulma:init");
        document.body.dispatchEvent(event);
      } else {
        window.addEventListener("load", (_loadEvent) => {
          // Emit a bulma init event to make sure that the filter dropdown is initialized.
          let event = new Event("bulma:init");
          document.body.dispatchEvent(event);
        });
      }
    });
}

function refreshLibrary() {
  loadGames();
}

function activateModal(game: any = {}) {
  if (!props.isEditable) {
    return;
  }
  document.documentElement.classList.add("is-clipped");

  // TODO: Probably replace this with a check for null/undefined?
  doesGamePurchaseExist.value = Object.entries(game).length > 0 ? false : true;
  currentGame.value = game;
  isModalActive.value = true;
}

function deactivateModal() {
  document.documentElement.classList.remove("is-clipped");

  isModalActive.value = false;
}

function activateEditBar() {
  isEditBarActive.value = true;
}

function deactivateEditBar() {
  isEditBarActive.value = false;
}

function selectedGamePurchasesChanged(gamePurchases: any[]) {
  gamePurchases.length > 0 ? activateEditBar() : deactivateEditBar();
  selectedGamePurchases.value = gamePurchases;
}

function closeEditBar() {
  // This will clear the selected games and deactivate the edit bar.
  selectedGamePurchasesChanged([]);
}

function closeAndRefresh() {
  deactivateModal();
  // Give it some time for the change to persist on the backend.
  setTimeout(() => {
    refreshLibrary();
  }, 750);
}

// Computed properties
const gameModalState = computed(() => {
  let currentGameExists = Object.keys(currentGame.value).length > 0;
  return currentGameExists ? "update" : "create";
});

// Lifecycle
onMounted(() => {
  loadGames();
});
</script>
