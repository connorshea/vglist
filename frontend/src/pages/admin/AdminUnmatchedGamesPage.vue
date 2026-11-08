<template>
  <div>
    <div v-if="!ugLoaded && ugLoading" class="has-text-centered py-6">Loading...</div>
    <div v-if="ugError" class="notification is-danger">{{ ugError }}</div>

    <template v-if="ugLoaded">
      <div class="table-container">
        <table class="table is-fullwidth is-striped is-narrow">
          <thead>
            <tr>
              <th>Count</th>
              <th>Service</th>
              <th>Service ID</th>
              <th>Game Name</th>
              <th>Wikidata</th>
              <th>Actions</th>
            </tr>
          </thead>
          <tbody>
            <tr v-for="game in ugGames" :key="`${game.externalServiceName}:${game.externalServiceId}`">
              <td>{{ game.count }}</td>
              <td>{{ game.externalServiceName }}</td>
              <td>
                <a
                  v-if="game.externalServiceName === 'STEAM'"
                  :href="`https://store.steampowered.com/app/${game.externalServiceId}`"
                  target="_blank"
                  rel="noopener noreferrer"
                >
                  {{ game.externalServiceId }}
                </a>
                <template v-else>{{ game.externalServiceId }}</template>
              </td>
              <td>{{ game.name }}</td>
              <td>
                <a
                  :href="`https://www.wikidata.org/w/index.php?search=${encodeURIComponent(game.name)}`"
                  target="_blank"
                  rel="noopener noreferrer"
                  class="mr-2"
                >
                  Search
                </a>
                <a
                  :href="`https://www.wikidata.org/w/index.php?title=Special:NewItem&label=${encodeURIComponent(game.name)}&description=video+game`"
                  target="_blank"
                  rel="noopener noreferrer"
                >
                  Create
                </a>
              </td>
              <td>
                <div class="unmatched-actions">
                  <button
                    v-if="game.externalServiceName === 'STEAM'"
                    type="button"
                    class="button is-small is-warning is-outlined"
                    @click="blocklistCandidate = { name: game.name, steamAppId: game.externalServiceId }"
                  >
                    Add to blocklist
                  </button>
                  <button
                    class="button is-small is-danger is-outlined"
                    @click="removeUnmatchedGame(game.externalServiceId, game.externalServiceName)"
                  >
                    Delete
                  </button>
                </div>
              </td>
            </tr>
          </tbody>
        </table>
      </div>
      <AdminLoadMore
        :has-next-page="ugHasNextPage"
        :loading="ugLoadingMore"
        :error="ugLoadMoreError"
        noun="games"
        @load-more="ugLoadMore"
      />
      <p v-if="ugGames.length === 0" class="has-text-centered has-text-grey py-4">No unmatched games.</p>
    </template>

    <ConfirmDialog
      :model-value="blocklistCandidate !== null"
      title="Add to the Steam blocklist?"
      confirm-label="Add to blocklist"
      loading-label="Adding…"
      variant="primary"
      :loading="addingToBlocklist"
      @update:model-value="blocklistCandidate = null"
      @confirm="blocklistUnmatchedGame"
    >
      <template #icon>
        <Ban :size="20" :stroke-width="2" aria-hidden="true" />
      </template>
      <template v-if="blocklistCandidate">
        <strong>{{ blocklistCandidate.name }}</strong> (Steam app {{ blocklistCandidate.steamAppId }}) will be skipped
        by future Steam imports, and its unmatched entries will be removed.
      </template>
    </ConfirmDialog>
  </div>
</template>

<script setup lang="ts">
import { ref } from "vue";
import { Ban } from "@lucide/vue";
import ConfirmDialog from "@/components/ConfirmDialog.vue";
import AdminLoadMore from "@/components/admin/AdminLoadMore.vue";
import { useConnectionList } from "@/composables/useConnectionList";
import { useSnackbar } from "@/composables/useSnackbar";
import { gqlClient } from "@/graphql/client";
import { GET_UNMATCHED_GAMES } from "@/graphql/queries/admin";
import { ADD_TO_STEAM_BLOCKLIST, REMOVE_FROM_UNMATCHED_GAMES } from "@/graphql/mutations/admin";
import { extractGqlError } from "@/utils/graphql-errors";
import type { GetUnmatchedGamesQuery } from "@/types/graphql";

const { show: showSnackbar } = useSnackbar();

const {
  nodes: ugGames,
  loaded: ugLoaded,
  loading: ugLoading,
  error: ugError,
  hasNextPage: ugHasNextPage,
  loadMore: ugLoadMore,
  loadingMore: ugLoadingMore,
  loadMoreError: ugLoadMoreError,
  reload: ugRefetch
} = useConnectionList(GET_UNMATCHED_GAMES, {
  select: (data: GetUnmatchedGamesQuery) => data.groupedUnmatchedGames
});

// One-click blocklisting. The mutation also clears every unmatched entry for
// that Steam app, so refetching drops the row.
const blocklistCandidate = ref<{ name: string; steamAppId: string } | null>(null);
const addingToBlocklist = ref(false);

async function blocklistUnmatchedGame() {
  const candidate = blocklistCandidate.value;
  if (!candidate) {
    return;
  }
  addingToBlocklist.value = true;
  try {
    await gqlClient.request(ADD_TO_STEAM_BLOCKLIST, {
      name: candidate.name,
      steamAppId: Number(candidate.steamAppId)
    });
    showSnackbar(`Added ${candidate.name} to the Steam blocklist.`);
    blocklistCandidate.value = null;
    ugRefetch();
  } catch (err) {
    showSnackbar(extractGqlError(err), "error");
  } finally {
    addingToBlocklist.value = false;
  }
}

async function removeUnmatchedGame(externalServiceId: string, externalServiceName: string) {
  try {
    await gqlClient.request(REMOVE_FROM_UNMATCHED_GAMES, { externalServiceId, externalServiceName });
    showSnackbar("Unmatched game removed.");
    ugRefetch();
  } catch (err) {
    showSnackbar(extractGqlError(err), "error");
  }
}
</script>

<style scoped>
.unmatched-actions {
  display: flex;
  flex-wrap: wrap;
  gap: 0.5rem;
}
</style>
