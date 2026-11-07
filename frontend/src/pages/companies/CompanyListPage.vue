<template>
  <ResourceIndex
    v-model:search="index.searchText.value"
    title="Companies"
    kind="company"
    kind-plural="companies"
    :items="items"
    :total-count="index.totalCount.value"
    :sort-links="index.sortLinks.value"
    :name-filter="index.nameFilter.value"
    :new-to="{ name: 'companyNew' }"
    :can-edit="authStore.isModerator"
    delete-consequence="removed from every game it developed or published."
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
import { GET_COMPANIES_INDEX } from "@/graphql/queries/resources";
import { DELETE_COMPANY } from "@/graphql/mutations/resources";
import { extractGqlError } from "@/utils/graphql-errors";
import type { GetCompaniesIndexQuery, DeleteCompanyMutation } from "@/types/graphql";
import ResourceIndex, { type ResourceIndexItem } from "@/components/resource-index/ResourceIndex.vue";
import { gamesMeta } from "@/components/resource-index/format";

const authStore = useAuthStore();
const { show: showSnackbar } = useSnackbar();

const index = useResourceIndex<
  GetCompaniesIndexQuery,
  NonNullable<GetCompaniesIndexQuery["companies"]>["nodes"][number]
>({
  document: GET_COMPANIES_INDEX,
  connection: (data) => data.companies,
  withConnection: (data, connection) => ({ ...data, companies: connection })
});

const items = computed<ResourceIndexItem[]>(() =>
  index.nodes.value.map((node) => ({
    id: node.id,
    name: node.name,
    meta: gamesMeta(node.gamesCount),
    coverGames: node.coverGames,
    to: { name: "company", params: { id: node.id } },
    editTo: { name: "companyEdit", params: { id: node.id } }
  }))
);

const { mutate: deleteRecord, loading: deleting } = useMutation<DeleteCompanyMutation>(DELETE_COMPANY);

async function onDelete(item: ResourceIndexItem, done: () => void) {
  try {
    await deleteRecord({ companyId: item.id });
    showSnackbar(`${item.name} has been deleted.`);
    await index.removeNode(item.id);
  } catch (e) {
    showSnackbar(`Failed to delete company: ${extractGqlError(e)}`, "error");
  } finally {
    done();
  }
}
</script>
