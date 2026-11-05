<template>
  <div>
    <div v-if="loading && !data" class="has-text-centered">
      <p>Loading platform...</p>
    </div>

    <div v-if="error && !data?.platform" class="notification is-danger">
      <p>Failed to load platform: {{ error.message }}</p>
    </div>

    <template v-if="data?.platform">
      <ResourceHeader
        kind="Platform"
        :icon="Gamepad2"
        :name="data.platform.name"
        :wikidata-id="data.platform.wikidataId"
        :edit-to="authStore.isModerator ? `/platforms/${data.platform.id}/edit` : null"
        @delete="showDeleteConfirm = true"
      >
        <template #facts>
          <span>
            <b>{{ data.platform.games.totalCount.toLocaleString() }}</b>
            {{ data.platform.games.totalCount === 1 ? "game" : "games" }}
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
        empty-text="No games are on this platform yet."
        :refreshing="loading"
        :has-next-page="hasNextPage"
        :loading-more="loadingMore"
        :load-more-error="loadMoreError"
        @load-more="loadMore"
      />

      <ConfirmDialog
        v-model="showDeleteConfirm"
        title="Delete platform?"
        confirm-label="Delete platform"
        loading-label="Deleting…"
        :loading="deleting"
        @confirm="confirmDelete"
      >
        <template #icon>
          <CircleAlert :size="22" :stroke-width="1.8" />
        </template>
        <strong>{{ data.platform.name }}</strong> will be permanently deleted, and removed from every game that uses it.
        This cannot be undone.
      </ConfirmDialog>
    </template>
  </div>
</template>

<script setup lang="ts">
import { ref, watch } from "vue";
import { useRoute, useRouter } from "vue-router";
import { CircleAlert, Gamepad2 } from "@lucide/vue";
import { useAuthStore } from "@/stores/auth";
import { useMutation } from "@/composables/useGraphQL";
import { useResourceGames } from "@/composables/useResourceGames";
import { useSnackbar } from "@/composables/useSnackbar";
import { GET_PLATFORM } from "@/graphql/queries/resources";
import { DELETE_PLATFORM } from "@/graphql/mutations/resources";
import { extractGqlError } from "@/utils/graphql-errors";
import type { GetPlatformQuery, DeletePlatformMutation } from "@/types/graphql";
import ResourceHeader from "@/components/resource/ResourceHeader.vue";
import ResourceGameList from "@/components/resource/ResourceGameList.vue";
import ConfirmDialog from "@/components/ConfirmDialog.vue";

const route = useRoute("platform");
const router = useRouter();
const authStore = useAuthStore();
const { show: showSnackbar } = useSnackbar();

const { data, loading, error, sortBy, games, hasNextPage, loadMore, loadingMore, loadMoreError } =
  useResourceGames<GetPlatformQuery>(GET_PLATFORM, {
    variables: () => ({ id: route.params.id }),
    select: (result) => result.platform?.games
  });

// Only a failed first load means the platform doesn't exist. Once it has
// loaded, an error from changing the sort is shown above the games instead.
watch([data, error, loading], () => {
  if (!loading.value && ((error.value && !data.value) || (data.value && !data.value.platform))) {
    router.replace({ name: "notFound" });
  }
});

const showDeleteConfirm = ref(false);
const { mutate: deletePlatform, loading: deleting } = useMutation<DeletePlatformMutation>(DELETE_PLATFORM);

async function confirmDelete() {
  try {
    await deletePlatform({ platformId: route.params.id });
    showSnackbar(`${data.value?.platform?.name ?? "Platform"} has been deleted.`);
    showDeleteConfirm.value = false;
    router.replace({ name: "platforms" });
  } catch (e) {
    showSnackbar(`Failed to delete platform: ${extractGqlError(e)}`, "error");
    showDeleteConfirm.value = false;
  }
}
</script>
