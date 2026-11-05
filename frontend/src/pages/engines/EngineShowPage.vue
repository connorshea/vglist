<template>
  <div>
    <div v-if="loading && !data" class="has-text-centered">
      <p>Loading engine...</p>
    </div>

    <div v-if="error && !data?.engine" class="notification is-danger">
      <p>Failed to load engine: {{ error.message }}</p>
    </div>

    <template v-if="data?.engine">
      <ResourceHeader
        kind="Engine"
        :icon="Cog"
        :name="data.engine.name"
        :wikidata-id="data.engine.wikidataId"
        :edit-to="authStore.isModerator ? `/engines/${data.engine.id}/edit` : null"
        @delete="showDeleteConfirm = true"
      >
        <template #facts>
          <span>
            <b>{{ data.engine.games.totalCount.toLocaleString() }}</b>
            {{ data.engine.games.totalCount === 1 ? "game" : "games" }}
          </span>
        </template>
      </ResourceHeader>

      <div v-if="error" class="notification is-danger mt-5">
        <p>Failed to load games: {{ error.message }}</p>
      </div>

      <ResourceGameList
        v-model:sort-by="sortBy"
        label="Games"
        :games="games"
        empty-text="No games use this engine yet."
        :refreshing="loading"
        :has-next-page="hasNextPage"
        :loading-more="loadingMore"
        :load-more-error="loadMoreError"
        @load-more="loadMore"
      />

      <ConfirmDialog
        v-model="showDeleteConfirm"
        title="Delete engine?"
        confirm-label="Delete engine"
        loading-label="Deleting…"
        :loading="deleting"
        @confirm="confirmDelete"
      >
        <template #icon>
          <CircleAlert :size="22" :stroke-width="1.8" />
        </template>
        <strong>{{ data.engine.name }}</strong> will be permanently deleted, and removed from every game that uses it.
        This cannot be undone.
      </ConfirmDialog>
    </template>
  </div>
</template>

<script setup lang="ts">
import { ref, watch } from "vue";
import { useRoute, useRouter } from "vue-router";
import { CircleAlert, Cog } from "@lucide/vue";
import { useAuthStore } from "@/stores/auth";
import { useMutation } from "@/composables/useGraphQL";
import { useResourceGames } from "@/composables/useResourceGames";
import { useSnackbar } from "@/composables/useSnackbar";
import { GET_ENGINE } from "@/graphql/queries/resources";
import { DELETE_ENGINE } from "@/graphql/mutations/resources";
import { extractGqlError } from "@/utils/graphql-errors";
import type { GetEngineQuery, DeleteEngineMutation } from "@/types/graphql";
import ResourceHeader from "@/components/resource/ResourceHeader.vue";
import ResourceGameList from "@/components/resource/ResourceGameList.vue";
import ConfirmDialog from "@/components/ConfirmDialog.vue";

const route = useRoute("engine");
const router = useRouter();
const authStore = useAuthStore();
const { show: showSnackbar } = useSnackbar();

const { data, loading, error, sortBy, games, hasNextPage, loadMore, loadingMore, loadMoreError } =
  useResourceGames<GetEngineQuery>(GET_ENGINE, {
    variables: () => ({ id: route.params.id }),
    select: (result) => result.engine?.games
  });

// Only a failed first load means the engine doesn't exist. Once it has
// loaded, an error from changing the sort is shown above the games instead.
watch([data, error, loading], () => {
  if (!loading.value && ((error.value && !data.value) || (data.value && !data.value.engine))) {
    router.replace({ name: "notFound" });
  }
});

const showDeleteConfirm = ref(false);
const { mutate: deleteEngine, loading: deleting } = useMutation<DeleteEngineMutation>(DELETE_ENGINE);

async function confirmDelete() {
  try {
    await deleteEngine({ engineId: route.params.id });
    showSnackbar(`${data.value?.engine?.name ?? "Engine"} has been deleted.`);
    showDeleteConfirm.value = false;
    router.replace({ name: "engines" });
  } catch (e) {
    showSnackbar(`Failed to delete engine: ${extractGqlError(e)}`, "error");
    showDeleteConfirm.value = false;
  }
}
</script>
