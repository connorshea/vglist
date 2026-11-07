<template>
  <div>
    <div v-if="loading && !data" class="has-text-centered">
      <p>Loading company...</p>
    </div>

    <div v-if="error && !data?.company" class="notification is-danger">
      <p>Failed to load company: {{ error.message }}</p>
    </div>

    <template v-if="data?.company">
      <ResourceHeader
        kind="Company"
        :icon="BriefcaseBusiness"
        :name="data.company.name"
        :wikidata-id="data.company.wikidataId"
        :edit-to="authStore.isModerator ? `/companies/${data.company.id}/edit` : null"
        @delete="showDeleteConfirm = true"
      >
        <template #facts>
          <span
            ><b>{{ data.company.developedCount.totalCount.toLocaleString() }}</b> developed</span
          >
          <span
            ><b>{{ data.company.publishedCount.totalCount.toLocaleString() }}</b> published</span
          >
        </template>
        <template #tabs>
          <ResourceTabs label="Company games" :tabs="tabs" />
        </template>
      </ResourceHeader>

      <div v-if="error" class="notification is-danger mt-5">
        <p>Failed to load games: {{ error.message }}</p>
      </div>

      <ResourceGameList
        v-model:sort-by="sortBy"
        :label="developed ? 'Developed games' : 'Published games'"
        :games="games"
        :empty-text="developed ? 'No games developed by this company yet.' : 'No games published by this company yet.'"
        :refreshing="loading"
        :has-next-page="hasNextPage"
        :loading-more="loadingMore"
        :load-more-error="loadMoreError"
        @load-more="loadMore"
      />

      <ConfirmDialog
        v-model="showDeleteConfirm"
        title="Delete company?"
        confirm-label="Delete company"
        loading-label="Deleting…"
        :loading="deleting"
        @confirm="confirmDelete"
      >
        <template #icon>
          <CircleAlert :size="22" :stroke-width="1.8" />
        </template>
        <strong>{{ data.company.name }}</strong> will be permanently deleted, and removed from every game it developed
        or published. This cannot be undone.
      </ConfirmDialog>
    </template>
  </div>
</template>

<script setup lang="ts">
import { computed, ref, watch } from "vue";
import { useRoute, useRouter } from "vue-router";
import { notFoundLocation } from "@/utils/not-found";
import { BriefcaseBusiness, CircleAlert } from "@lucide/vue";
import { useAuthStore } from "@/stores/auth";
import { useMutation } from "@/composables/useGraphQL";
import { useResourceGames } from "@/composables/useResourceGames";
import { usePageTitle } from "@/composables/usePageTitle";
import { useSnackbar } from "@/composables/useSnackbar";
import { GET_COMPANY } from "@/graphql/queries/resources";
import { DELETE_COMPANY } from "@/graphql/mutations/resources";
import { extractGqlError } from "@/utils/graphql-errors";
import type { GetCompanyQuery, DeleteCompanyMutation } from "@/types/graphql";
import ResourceHeader from "@/components/resource/ResourceHeader.vue";
import ResourceTabs from "@/components/resource/ResourceTabs.vue";
import ResourceGameList from "@/components/resource/ResourceGameList.vue";
import ConfirmDialog from "@/components/ConfirmDialog.vue";

const route = useRoute("company");
const router = useRouter();
const authStore = useAuthStore();
const { show: showSnackbar } = useSnackbar();

// The Developed tab is the default and is left out of the URL.
const developed = computed(() => route.query.tab !== "published");

const { data, loading, error, sortBy, games, hasNextPage, loadMore, loadingMore, loadMoreError } =
  useResourceGames<GetCompanyQuery>(GET_COMPANY, {
    variables: () => ({ id: route.params.id, developed: developed.value }),
    select: (result) => (developed.value ? result.company?.developedGames : result.company?.publishedGames)
  });

usePageTitle(() => data.value?.company?.name);

const tabs = computed(() => {
  const company = data.value?.company;
  return [
    {
      label: "Developed",
      count: company?.developedCount.totalCount ?? 0,
      to: { query: { ...route.query, tab: undefined } },
      active: developed.value
    },
    {
      label: "Published",
      count: company?.publishedCount.totalCount ?? 0,
      to: { query: { ...route.query, tab: "published" } },
      active: !developed.value
    }
  ];
});

// Only a failed first load means the company doesn't exist. Once it has
// loaded, an error from changing the sort or tab is shown above the games.
watch([data, error, loading], () => {
  if (!loading.value && ((error.value && !data.value) || (data.value && !data.value.company))) {
    router.replace(notFoundLocation(route));
  }
});

const showDeleteConfirm = ref(false);
const { mutate: deleteCompany, loading: deleting } = useMutation<DeleteCompanyMutation>(DELETE_COMPANY);

async function confirmDelete() {
  try {
    await deleteCompany({ companyId: route.params.id });
    showSnackbar(`${data.value?.company?.name ?? "Company"} has been deleted.`);
    showDeleteConfirm.value = false;
    router.replace({ name: "companies" });
  } catch (e) {
    showSnackbar(`Failed to delete company: ${extractGqlError(e)}`, "error");
    showDeleteConfirm.value = false;
  }
}
</script>
