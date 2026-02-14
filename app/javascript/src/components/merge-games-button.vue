<template>
  <div>
    <a @click="activateModal" class="dropdown-item has-text-danger js-merge-games-button">
      Merge
    </a>

    <merge-games-modal
      v-if="isModalActive"
      :isActive="isModalActive"
      :game="game"
      @close="deactivateModal"
      @save="onSubmit"
    ></merge-games-modal>
  </div>
</template>

<script setup lang="ts">
import { ref } from "vue";
import MergeGamesModal from "./merge-games-modal.vue";
import Turbolinks from "turbolinks";

interface Props {
  game: { id: number; name: string };
}

const props = defineProps<Props>();

const isModalActive = ref(false);

function activateModal() {
  document.documentElement.classList.add("is-clipped");
  isModalActive.value = true;
}

function deactivateModal() {
  document.documentElement.classList.remove("is-clipped");
  isModalActive.value = false;
}

function onSubmit() {
  Turbolinks.visit(window.location.href);
}
</script>
