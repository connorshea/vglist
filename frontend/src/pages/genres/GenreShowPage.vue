<template>
  <div>
    <div v-if="loading && !data" class="has-text-centered">
      <p>Loading genre...</p>
    </div>

    <div v-if="error && !data?.genre" class="notification is-danger">
      <p>Failed to load genre: {{ error.message }}</p>
    </div>

    <template v-if="data?.genre">
      <ResourceHeader
        kind="Genre"
        :icon="Tag"
        :name="data.genre.name"
        :wikidata-id="data.genre.wikidataId"
        :edit-to="authStore.isModerator ? `/genres/${data.genre.id}/edit` : null"
        @delete="showDeleteConfirm = true"
      >
        <template #facts>
          <span>
            <b>{{ data.genre.games.totalCount.toLocaleString() }}</b>
            {{ data.genre.games.totalCount === 1 ? "game" : "games" }}
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
        empty-text="No games are in this genre yet."
        :refreshing="loading"
        :has-next-page="hasNextPage"
        :loading-more="loadingMore"
        :load-more-error="loadMoreError"
        @load-more="loadMore"
      />

      <ConfirmDialog
        v-model="showDeleteConfirm"
        title="Delete genre?"
        confirm-label="Delete genre"
        loading-label="Deleting…"
        :loading="deleting"
        @confirm="confirmDelete"
      >
        <template #icon>
          <CircleAlert :size="22" :stroke-width="1.8" />
        </template>
        <strong>{{ data.genre.name }}</strong> will be permanently deleted, and removed from every game in it. This
        cannot be undone.
      </ConfirmDialog>
    </template>
  </div>
</template>

<script setup lang="ts">
import { ref, watch } from "vue";
import { useRoute, useRouter } from "vue-router";
import { CircleAlert, Tag } from "@lucide/vue";
import { useAuthStore } from "@/stores/auth";
import { useMutation } from "@/composables/useGraphQL";
import { useResourceGames } from "@/composables/useResourceGames";
import { useSnackbar } from "@/composables/useSnackbar";
import { GET_GENRE } from "@/graphql/queries/resources";
import { DELETE_GENRE } from "@/graphql/mutations/resources";
import { extractGqlError } from "@/utils/graphql-errors";
import type { GetGenreQuery, DeleteGenreMutation } from "@/types/graphql";
import ResourceHeader from "@/components/resource/ResourceHeader.vue";
import ResourceGameList from "@/components/resource/ResourceGameList.vue";
import ConfirmDialog from "@/components/ConfirmDialog.vue";

const route = useRoute("genre");
const router = useRouter();
const authStore = useAuthStore();
const { show: showSnackbar } = useSnackbar();

const { data, loading, error, sortBy, games, hasNextPage, loadMore, loadingMore, loadMoreError } =
  useResourceGames<GetGenreQuery>(GET_GENRE, {
    variables: () => ({ id: route.params.id }),
    select: (result) => result.genre?.games
  });

// Only a failed first load means the genre doesn't exist. Once it has
// loaded, an error from changing the sort is shown above the games instead.
watch([data, error, loading], () => {
  if (!loading.value && ((error.value && !data.value) || (data.value && !data.value.genre))) {
    router.replace({ name: "notFound" });
  }
});

const showDeleteConfirm = ref(false);
const { mutate: deleteGenre, loading: deleting } = useMutation<DeleteGenreMutation>(DELETE_GENRE);

async function confirmDelete() {
  try {
    await deleteGenre({ genreId: route.params.id });
    showSnackbar(`${data.value?.genre?.name ?? "Genre"} has been deleted.`);
    showDeleteConfirm.value = false;
    router.replace({ name: "genres" });
  } catch (e) {
    showSnackbar(`Failed to delete genre: ${extractGqlError(e)}`, "error");
    showDeleteConfirm.value = false;
  }
}
</script>
