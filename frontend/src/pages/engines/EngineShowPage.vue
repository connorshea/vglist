<template>
  <section class="section">
    <div v-if="loading && !data" class="has-text-centered">
      <p>Loading engine...</p>
    </div>

    <div v-if="error" class="notification is-danger">
      <p>Failed to load engine: {{ error.message }}</p>
    </div>

    <div v-if="data?.engine">
      <h1 class="title">{{ data.engine.name }}</h1>

      <p v-if="data.engine.wikidataId" class="subtitle is-6">
        <a :href="`https://www.wikidata.org/wiki/Q${data.engine.wikidataId}`" target="_blank" rel="noopener noreferrer"
          >Wikidata</a
        >
      </p>

      <div v-if="authStore.isModerator" class="buttons">
        <router-link :to="`/engines/${data.engine.id}/edit`" class="button is-small">Edit</router-link>
        <button class="button is-small is-danger is-light" @click="showDeleteConfirm = true">Delete</button>
      </div>

      <h2 class="title is-4 mt-5">Games</h2>

      <div class="columns is-multiline">
        <div v-for="game in data.engine.games.nodes" :key="game.id" class="column is-3">
          <GameCard :id="game.id" :name="game.name" :cover-url="game.coverUrl ?? null" />
        </div>
      </div>

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
import { GET_ENGINE } from "@/graphql/queries/resources";
import { DELETE_ENGINE } from "@/graphql/mutations/resources";
import { extractGqlError } from "@/utils/graphql-errors";
import type { GetEngineQuery, DeleteEngineMutation } from "@/types/graphql";
import GameCard from "@/components/GameCard.vue";
import ConfirmDialog from "@/components/ConfirmDialog.vue";

const route = useRoute("engine");
const router = useRouter();
const authStore = useAuthStore();
const { show: showSnackbar } = useSnackbar();

const { data, loading, error } = useQuery<GetEngineQuery>(GET_ENGINE, {
  variables: { id: route.params.id }
});

watch([data, error, loading], () => {
  if (!loading.value && (error.value || (data.value && !data.value.engine))) {
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
