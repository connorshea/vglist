<template>
  <GameLibrarySheet
    :variant="variant"
    title="Edit library entry"
    :game-name="purchase.game.name"
    :cover-url="purchase.game.coverUrl ?? null"
    @close="emit('close')"
  >
    <p v-if="gameLoading && !gameData" class="library-editor-loading" role="status">Loading…</p>
    <GameLibraryForm
      v-else
      :variant="variant"
      :game-id="purchase.game.id"
      :game-name="purchase.game.name"
      :game-purchase-id="purchase.id"
      :game-platforms="gamePlatforms"
      :all-stores="allStores"
      :stores-loading="storesLoading"
      :removing-from-library="removing"
      @cancel="emit('close')"
      @saved="onSaved"
      @request-remove="showRemoveConfirm = true"
      @error="onError"
    />
  </GameLibrarySheet>

  <ConfirmDialog v-model="showRemoveConfirm" title="Remove game?" :loading="removing" @confirm="confirmRemove">
    <template #icon>
      <CircleAlert :size="22" :stroke-width="1.8" />
    </template>
    <strong>{{ purchase.game.name }}</strong> will be removed from your library. Your rating, status, and notes will be
    deleted.
  </ConfirmDialog>
</template>

<script setup lang="ts">
import { computed, ref } from "vue";
import { CircleAlert } from "@lucide/vue";
import { useQuery } from "@/composables/useGraphQL";
import { useSnackbar } from "@/composables/useSnackbar";
import { gqlClient } from "@/graphql/client";
import { REMOVE_GAME_FROM_LIBRARY } from "@/graphql/mutations/games";
import { GET_LIBRARY_ENTRY_GAME } from "@/graphql/queries/library";
import { GET_STORES } from "@/graphql/queries/resources";
import type { GetLibraryEntryGameQuery, GetStoresQuery, LibraryGamePurchaseFieldsFragment } from "@/types/graphql";
import { extractGqlError } from "@/utils/graphql-errors";
import ConfirmDialog from "@/components/ConfirmDialog.vue";
import GameLibraryForm from "@/components/game/GameLibraryForm.vue";
import GameLibrarySheet from "@/components/game/GameLibrarySheet.vue";

// The game page's library drawer (or phone sheet), opened from a library tile
// for a game that's already in the library.
const props = withDefaults(
  defineProps<{
    purchase: LibraryGamePurchaseFieldsFragment;
    variant?: "drawer" | "sheet";
  }>(),
  { variant: "drawer" }
);

const emit = defineEmits<{
  close: [];
  // The entry was saved or removed, so the library on screen is out of date.
  changed: [];
}>();

const { show: showSnackbar } = useSnackbar();

// The form only offers the game's own platforms, so they're fetched first.
const { data: gameData, loading: gameLoading } = useQuery<GetLibraryEntryGameQuery>(GET_LIBRARY_ENTRY_GAME, {
  variables: () => ({ id: props.purchase.game.id })
});
const gamePlatforms = computed(() => gameData.value?.game?.platforms.nodes ?? []);

const { data: storesData, loading: storesLoading } = useQuery<GetStoresQuery>(GET_STORES, {
  variables: { first: 100 }
});
const allStores = computed(() => storesData.value?.stores?.nodes ?? []);

function onSaved(message: string) {
  showSnackbar(message);
  emit("changed");
  emit("close");
}

function onError(message: string) {
  showSnackbar(message, "error");
}

const showRemoveConfirm = ref(false);
const removing = ref(false);

async function confirmRemove() {
  removing.value = true;
  try {
    await gqlClient.request(REMOVE_GAME_FROM_LIBRARY, { gamePurchaseId: props.purchase.id });
    localStorage.removeItem(`vglist-review-draft-${props.purchase.game.id}`);
    showSnackbar(`${props.purchase.game.name} has been removed from your library.`);
    showRemoveConfirm.value = false;
    emit("changed");
    emit("close");
  } catch (err) {
    showRemoveConfirm.value = false;
    showSnackbar(`Failed to remove game from library: ${extractGqlError(err)}`, "error");
  } finally {
    removing.value = false;
  }
}
</script>

<style scoped>
.library-editor-loading {
  padding: 24px 20px;
  color: var(--color-text-secondary);
  font-size: 0.875rem;
}
</style>
