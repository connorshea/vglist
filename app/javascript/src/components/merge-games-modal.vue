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
            {{ errors.length > 1 ? "Errors" : "An error" }} prevented this game from being merged:
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
        <button
          @click="onSave"
          class="button is-primary js-submit-button"
          :disabled="!gameSelected"
        >
          Submit
        </button>
        <button @click="onClose" class="button">Cancel</button>
      </footer>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref } from "vue";
import type { Option } from "vue3-select-component";
import SingleSelect from "./fields/single-select.vue";
import VglistUtils from "../utils";
import Turbolinks from "turbolinks";

interface Props {
  game: { id: number; name: string };
  isActive: boolean;
}

const props = withDefaults(defineProps<Props>(), {
  game: () => ({ id: 0, name: "" }),
});

const emit = defineEmits(["close", "save"]);

const errors = ref<string[]>([]);
const gameSelected = ref(false);
const gameA = ref<Option<number> | null>(null);

function onClose() {
  emit("close");
}

function onSave() {
  if (!gameA.value) {
    errors.value = ["Please select a game"];
    return;
  }

  const gameAId = gameA.value.value; // Extract ID from Option format
  const gameBId = props.game.id;
  const mergePath = `/games/${gameAId}/merge/${gameBId}.json`;

  VglistUtils.rawAuthenticatedFetch(mergePath, "POST").then((response) => {
    // HTTP 301 response
    if (response.redirected) {
      Turbolinks.clearCache();
      Turbolinks.visit(response.url);
      // If it's not a redirect, check it for errors and display them.
    } else {
      response.json().then((json) => {
        errors.value = json.errors;
      });
      const submitButton = document.querySelector(".js-submit-button");
      if (submitButton) {
        submitButton.classList.add("js-submit-button-error");
        setTimeout(() => {
          submitButton.classList.remove("js-submit-button-error");
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
function customOptionLabel(item: { id: number; name: string }): Option<number> {
  return { value: item.id, label: `${item.name} (${item.id})` };
}
</script>
