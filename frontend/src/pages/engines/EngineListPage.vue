<template>
  <ResourceIndex
    v-model:search="index.searchText.value"
    title="Engines"
    kind="engine"
    kind-plural="engines"
    :items="items"
    :total-count="index.totalCount.value"
    :sort-links="index.sortLinks.value"
    :name-filter="index.nameFilter.value"
    :new-to="{ name: 'engineNew' }"
    :can-edit="authStore.isModerator"
    delete-consequence="removed from every game that uses it."
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
import { GET_ENGINES_INDEX } from "@/graphql/queries/resources";
import { DELETE_ENGINE } from "@/graphql/mutations/resources";
import { extractGqlError } from "@/utils/graphql-errors";
import type { GetEnginesIndexQuery, DeleteEngineMutation } from "@/types/graphql";
import ResourceIndex, { type ResourceIndexItem } from "@/components/resource-index/ResourceIndex.vue";
import { gamesMeta } from "@/components/resource-index/format";

const authStore = useAuthStore();
const { show: showSnackbar } = useSnackbar();

const index = useResourceIndex<GetEnginesIndexQuery, NonNullable<GetEnginesIndexQuery["engines"]>["nodes"][number]>({
  document: GET_ENGINES_INDEX,
  connection: (data) => data.engines,
  withConnection: (data, connection) => ({ ...data, engines: connection })
});

const items = computed<ResourceIndexItem[]>(() =>
  index.nodes.value.map((node) => ({
    id: node.id,
    name: node.name,
    meta: gamesMeta(node.gamesCount),
    coverGames: node.coverGames,
    to: { name: "engine", params: { id: node.id } },
    editTo: { name: "engineEdit", params: { id: node.id } }
  }))
);

const { mutate: deleteRecord, loading: deleting } = useMutation<DeleteEngineMutation>(DELETE_ENGINE);

async function onDelete(item: ResourceIndexItem, done: () => void) {
  try {
    await deleteRecord({ engineId: item.id });
    showSnackbar(`${item.name} has been deleted.`);
    await index.removeNode(item.id);
  } catch (e) {
    showSnackbar(`Failed to delete engine: ${extractGqlError(e)}`, "error");
  } finally {
    done();
  }
}
</script>
