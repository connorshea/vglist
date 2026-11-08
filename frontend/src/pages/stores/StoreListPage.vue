<template>
  <div>
    <h1 class="title">Stores</h1>

    <div v-if="authStore.isModerator" class="buttons">
      <router-link to="/stores/new" class="button is-small is-primary">New Store</router-link>
    </div>

    <div v-if="loading && !data" class="has-text-centered">
      <p>Loading stores...</p>
    </div>

    <div v-if="error" class="notification is-danger">
      <p>Failed to load stores: {{ error.message }}</p>
    </div>

    <ul v-if="data" class="store-list">
      <li v-for="store in data?.stores?.nodes" :key="store.id" class="store-row">
        <span class="store-name">{{ store.name }}</span>
        <span v-if="authStore.isModerator" class="store-actions">
          <router-link
            :to="{ name: 'storeEdit', params: { id: store.id } }"
            class="button is-small"
            :aria-label="`Edit ${store.name}`"
            >Edit</router-link
          >
          <button
            type="button"
            class="button is-small is-danger is-light"
            :aria-label="`Delete ${store.name}`"
            @click="storeToDelete = store"
          >
            Delete
          </button>
        </span>
      </li>
    </ul>

    <PaginationNav
      v-if="data && (currentPage > 1 || hasNextPage)"
      :current-page="currentPage"
      :has-next-page="hasNextPage"
      :loading="loading"
      @prev="prevPage"
      @next="nextPage"
    />

    <ConfirmDialog
      v-model="showDeleteConfirm"
      title="Delete store?"
      confirm-label="Delete store"
      loading-label="Deleting…"
      :loading="deleting"
      @confirm="confirmDelete"
    >
      <template #icon>
        <CircleAlert :size="22" :stroke-width="1.8" />
      </template>
      <strong>{{ storeToDelete?.name }}</strong> will be permanently deleted, and removed from every library entry that
      uses it. This cannot be undone.
    </ConfirmDialog>
  </div>
</template>

<script setup lang="ts">
import { ref, watch, computed } from "vue";
import { CircleAlert } from "@lucide/vue";
import { useAuthStore } from "@/stores/auth";
import { useRoute, useRouter } from "vue-router";
import { useQuery, useMutation } from "@/composables/useGraphQL";
import { useCursorPages, withoutPage } from "@/composables/useCursorPages";
import { useSnackbar } from "@/composables/useSnackbar";
import { GET_STORES } from "@/graphql/queries/resources";
import { DELETE_STORE } from "@/graphql/mutations/resources";
import { extractGqlError } from "@/utils/graphql-errors";
import type { GetStoresQuery, DeleteStoreMutation } from "@/types/graphql";
import PaginationNav from "@/components/PaginationNav.vue";
import ConfirmDialog from "@/components/ConfirmDialog.vue";

const authStore = useAuthStore();
const { show: showSnackbar } = useSnackbar();

const PAGE_SIZE = 25;
const route = useRoute();
const router = useRouter();
// The page lives in the query string, so Back and Forward step through pages.
const {
  currentPage,
  variables: pageVariables,
  nextPage: goToNextPage,
  prevPage: goToPrevPage
} = useCursorPages(PAGE_SIZE);

const { data, loading, error, refetch } = useQuery<GetStoresQuery>(GET_STORES, {
  variables: () => pageVariables.value
});

const hasNextPage = computed(() => data.value?.stores?.pageInfo.hasNextPage ?? false);

watch(data, (val) => {
  // Deleting the last store on a later page leaves that page empty, and an
  // empty page has no cursor to step back from, so start over from the first.
  if (val?.stores?.nodes.length === 0 && currentPage.value > 1) {
    void router.replace({ query: withoutPage(route.query) });
  }
});

function nextPage() {
  if (hasNextPage.value) {
    goToNextPage(data.value?.stores?.pageInfo.endCursor);
  }
}

function prevPage() {
  goToPrevPage(data.value?.stores?.pageInfo.startCursor);
}

type StoreNode = NonNullable<GetStoresQuery["stores"]>["nodes"][number];

const storeToDelete = ref<StoreNode | null>(null);
const showDeleteConfirm = computed({
  get: () => storeToDelete.value !== null,
  set: (open) => {
    if (!open) {
      storeToDelete.value = null;
    }
  }
});

const { mutate: deleteStore, loading: deleting } = useMutation<DeleteStoreMutation>(DELETE_STORE);

async function confirmDelete() {
  const store = storeToDelete.value;
  if (!store) {
    return;
  }

  try {
    await deleteStore({ storeId: store.id });
    showSnackbar(`${store.name} has been deleted.`);
    void refetch();
  } catch (e) {
    showSnackbar(`Failed to delete store: ${extractGqlError(e)}`, "error");
  } finally {
    storeToDelete.value = null;
  }
}
</script>

<style scoped>
.store-list {
  max-width: 40rem;
}

.store-row {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 1rem;
  padding: 0.6rem 0;
  border-bottom: 1px solid var(--color-border);
}

.store-name {
  min-width: 0;
  overflow-wrap: anywhere;
}

.store-actions {
  display: flex;
  gap: 0.5rem;
  flex-shrink: 0;
}
</style>
