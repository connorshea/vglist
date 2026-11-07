<template>
  <div>
    <div v-if="loading && !data" class="has-text-centered">
      <p>Loading series...</p>
    </div>

    <div v-if="error && !data?.series" class="notification is-danger">
      <p>Failed to load series: {{ error.message }}</p>
    </div>

    <template v-if="data?.series">
      <ResourceHeader
        kind="Series"
        :icon="Library"
        :name="data.series.name"
        :wikidata-id="data.series.wikidataId"
        :edit-to="authStore.isModerator ? `/series/${data.series.id}/edit` : null"
        @delete="showDeleteConfirm = true"
      >
        <template #facts>
          <span>
            <b>{{ data.series.games.totalCount.toLocaleString() }}</b>
            {{ data.series.games.totalCount === 1 ? "game" : "games" }}
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
        empty-text="No games are in this series yet."
        :refreshing="loading"
        :has-next-page="hasNextPage"
        :loading-more="loadingMore"
        :load-more-error="loadMoreError"
        @load-more="loadMore"
      />

      <ConfirmDialog
        v-model="showDeleteConfirm"
        title="Delete series?"
        confirm-label="Delete series"
        loading-label="Deleting…"
        :loading="deleting"
        @confirm="confirmDelete"
      >
        <template #icon>
          <CircleAlert :size="22" :stroke-width="1.8" />
        </template>
        <strong>{{ data.series.name }}</strong> will be permanently deleted, and removed from every game in it. This
        cannot be undone.
      </ConfirmDialog>
    </template>
  </div>
</template>

<script setup lang="ts">
import { ref, watch } from "vue";
import { useRoute, useRouter } from "vue-router";
import { CircleAlert, Library } from "@lucide/vue";
import { useAuthStore } from "@/stores/auth";
import { useMutation } from "@/composables/useGraphQL";
import { useResourceGames } from "@/composables/useResourceGames";
import { usePageTitle } from "@/composables/usePageTitle";
import { useSnackbar } from "@/composables/useSnackbar";
import { GET_SERIES } from "@/graphql/queries/resources";
import { DELETE_SERIES } from "@/graphql/mutations/resources";
import { extractGqlError } from "@/utils/graphql-errors";
import type { GetSeriesQuery, DeleteSeriesMutation } from "@/types/graphql";
import ResourceHeader from "@/components/resource/ResourceHeader.vue";
import ResourceGameList from "@/components/resource/ResourceGameList.vue";
import ConfirmDialog from "@/components/ConfirmDialog.vue";

const route = useRoute("series");
const router = useRouter();
const authStore = useAuthStore();
const { show: showSnackbar } = useSnackbar();

const { data, loading, error, sortBy, games, hasNextPage, loadMore, loadingMore, loadMoreError } =
  useResourceGames<GetSeriesQuery>(GET_SERIES, {
    variables: () => ({ id: route.params.id }),
    select: (result) => result.series?.games
  });

usePageTitle(() => data.value?.series?.name);

// Only a failed first load means the series doesn't exist. Once it has
// loaded, an error from changing the sort is shown above the games instead.
watch([data, error, loading], () => {
  if (!loading.value && ((error.value && !data.value) || (data.value && !data.value.series))) {
    router.replace({ name: "notFound" });
  }
});

const showDeleteConfirm = ref(false);
const { mutate: deleteSeries, loading: deleting } = useMutation<DeleteSeriesMutation>(DELETE_SERIES);

async function confirmDelete() {
  try {
    await deleteSeries({ seriesId: route.params.id });
    showSnackbar(`${data.value?.series?.name ?? "Series"} has been deleted.`);
    showDeleteConfirm.value = false;
    router.replace({ name: "seriesList" });
  } catch (e) {
    showSnackbar(`Failed to delete series: ${extractGqlError(e)}`, "error");
    showDeleteConfirm.value = false;
  }
}
</script>
