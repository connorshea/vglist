<template>
  <ResourceIndex
    v-model:search="index.searchText.value"
    title="Series"
    kind="series"
    kind-plural="series"
    :items="items"
    :total-count="index.totalCount.value"
    :sort-links="index.sortLinks.value"
    :name-filter="index.nameFilter.value"
    :new-to="{ name: 'seriesNew' }"
    :can-edit="authStore.isModerator"
    delete-consequence="removed from every game in it."
    :loaded="index.loaded.value"
    :loading="index.loading.value"
    :loading-more="index.loadingMore.value"
    :refreshing="index.refreshing.value"
    :has-next-page="index.hasNextPage.value"
    :deleting="deleting"
    :error="index.error.value"
    @load-more="index.loadMore"
    @delete="onDelete"
  />
</template>

<script setup lang="ts">
import { computed } from "vue";
import { useAuthStore } from "@/stores/auth";
import { useMutation } from "@/composables/useGraphQL";
import { useResourceIndex } from "@/composables/useResourceIndex";
import { useSnackbar } from "@/composables/useSnackbar";
import { GET_SERIES_INDEX } from "@/graphql/queries/resources";
import { DELETE_SERIES } from "@/graphql/mutations/resources";
import { extractGqlError } from "@/utils/graphql-errors";
import type { GetSeriesIndexQuery, DeleteSeriesMutation } from "@/types/graphql";
import ResourceIndex, { type ResourceIndexItem } from "@/components/resource-index/ResourceIndex.vue";
import { seriesMeta } from "@/components/resource-index/format";

const authStore = useAuthStore();
const { show: showSnackbar } = useSnackbar();

const index = useResourceIndex<GetSeriesIndexQuery, NonNullable<GetSeriesIndexQuery["seriesList"]>["nodes"][number]>({
  document: GET_SERIES_INDEX,
  connection: (data) => data.seriesList,
  withConnection: (data, connection) => ({ ...data, seriesList: connection })
});

const items = computed<ResourceIndexItem[]>(() =>
  index.nodes.value.map((node) => ({
    id: node.id,
    name: node.name,
    meta: seriesMeta(node.gamesCount, node.firstReleaseYear, node.lastReleaseYear),
    coverGames: node.coverGames,
    to: { name: "series", params: { id: node.id } },
    editTo: { name: "seriesEdit", params: { id: node.id } }
  }))
);

const { mutate: deleteRecord, loading: deleting } = useMutation<DeleteSeriesMutation>(DELETE_SERIES);

async function onDelete(item: ResourceIndexItem, done: () => void) {
  try {
    await deleteRecord({ seriesId: item.id });
    showSnackbar(`${item.name} has been deleted.`);
    await index.removeNode(item.id);
  } catch (e) {
    showSnackbar(`Failed to delete series: ${extractGqlError(e)}`, "error");
  } finally {
    done();
  }
}
</script>
