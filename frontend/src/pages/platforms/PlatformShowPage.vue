<template>
  <section class="section">
    <div v-if="loading && !data" class="has-text-centered">
      <p>Loading platform...</p>
    </div>

    <div v-if="error" class="notification is-danger">
      <p>Failed to load platform: {{ error.message }}</p>
    </div>

    <div v-if="data?.platform">
      <h1 class="title">{{ data.platform.name }}</h1>

      <p v-if="data.platform.wikidataId" class="subtitle is-6">
        <a
          :href="`https://www.wikidata.org/wiki/Q${data.platform.wikidataId}`"
          target="_blank"
          rel="noopener noreferrer"
          >Wikidata</a
        >
      </p>

      <div v-if="authStore.isModerator" class="buttons">
        <router-link :to="`/platforms/${data.platform.id}/edit`" class="button is-small">Edit</router-link>
        <button class="button is-small is-danger is-light" @click="showDeleteConfirm = true">Delete</button>
      </div>

      <h2 class="title is-4 mt-5">Games</h2>

      <div class="columns is-multiline">
        <div v-for="game in data.platform.games.nodes" :key="game.id" class="column is-3">
          <GameCard :id="game.id" :name="game.name" :cover-url="game.coverUrl ?? null" />
        </div>
      </div>

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
import { GET_PLATFORM } from "@/graphql/queries/resources";
import { DELETE_PLATFORM } from "@/graphql/mutations/resources";
import { extractGqlError } from "@/utils/graphql-errors";
import type { GetPlatformQuery, DeletePlatformMutation } from "@/types/graphql";
import GameCard from "@/components/GameCard.vue";
import ConfirmDialog from "@/components/ConfirmDialog.vue";

const route = useRoute("platform");
const router = useRouter();
const authStore = useAuthStore();
const { show: showSnackbar } = useSnackbar();

const { data, loading, error } = useQuery<GetPlatformQuery>(GET_PLATFORM, {
  variables: { id: route.params.id }
});

watch([data, error, loading], () => {
  if (!loading.value && (error.value || (data.value && !data.value.platform))) {
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
