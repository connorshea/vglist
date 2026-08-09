<template>
  <section class="section">
    <div v-if="loading && !data" class="has-text-centered">
      <p>Loading store...</p>
    </div>

    <div v-if="error" class="notification is-danger">
      <p>Failed to load store: {{ error.message }}</p>
    </div>

    <div v-if="data?.store">
      <h1 class="title">{{ data.store.name }}</h1>

      <div v-if="authStore.isModerator" class="buttons">
        <router-link :to="`/stores/${data.store.id}/edit`" class="button is-small">Edit</router-link>
        <button class="button is-small is-danger is-light" @click="showDeleteConfirm = true">Delete</button>
      </div>

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
        <strong>{{ data.store.name }}</strong> will be permanently deleted, and removed from every library entry that
        uses it. This cannot be undone.
      </ConfirmDialog>
    </div>
  </section>
</template>

<script setup lang="ts">
import { ref, watch } from "vue";
import { useRoute, useRouter } from "vue-router";
import { CircleAlert } from "@lucide/vue";
import { useAuthStore } from "@/stores/auth";
import { useQuery, useMutation } from "@/composables/useGraphQL";
import { useSnackbar } from "@/composables/useSnackbar";
import { GET_STORE } from "@/graphql/queries/resources";
import { DELETE_STORE } from "@/graphql/mutations/resources";
import { extractGqlError } from "@/utils/graphql-errors";
import type { GetStoreQuery, DeleteStoreMutation } from "@/types/graphql";
import ConfirmDialog from "@/components/ConfirmDialog.vue";

const route = useRoute("store");
const router = useRouter();
const authStore = useAuthStore();
const { show: showSnackbar } = useSnackbar();

const { data, loading, error } = useQuery<GetStoreQuery>(GET_STORE, {
  variables: { id: route.params.id }
});

watch([data, error, loading], () => {
  if (!loading.value && (error.value || (data.value && !data.value.store))) {
    router.replace({ name: "notFound" });
  }
});

const showDeleteConfirm = ref(false);
const { mutate: deleteStore, loading: deleting } = useMutation<DeleteStoreMutation>(DELETE_STORE);

async function confirmDelete() {
  try {
    await deleteStore({ storeId: route.params.id });
    showSnackbar(`${data.value?.store?.name ?? "Store"} has been deleted.`);
    showDeleteConfirm.value = false;
    router.replace({ name: "stores" });
  } catch (e) {
    showSnackbar(`Failed to delete store: ${extractGqlError(e)}`, "error");
    showDeleteConfirm.value = false;
  }
}
</script>
