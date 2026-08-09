<template>
  <section class="section">
    <div v-if="loading && !data" class="has-text-centered">
      <p>Loading genre...</p>
    </div>

    <div v-if="error" class="notification is-danger">
      <p>Failed to load genre: {{ error.message }}</p>
    </div>

    <div v-if="data?.genre">
      <h1 class="title">{{ data.genre.name }}</h1>

      <p v-if="data.genre.wikidataId" class="subtitle is-6">
        <a :href="`https://www.wikidata.org/wiki/Q${data.genre.wikidataId}`" target="_blank" rel="noopener noreferrer"
          >Wikidata</a
        >
      </p>

      <div v-if="authStore.isModerator" class="buttons">
        <router-link :to="`/genres/${data.genre.id}/edit`" class="button is-small">Edit</router-link>
        <button class="button is-small is-danger is-light" @click="showDeleteConfirm = true">Delete</button>
      </div>

      <h2 class="title is-4 mt-5">Games</h2>

      <div class="columns is-multiline">
        <div v-for="game in data.genre.games.nodes" :key="game.id" class="column is-3">
          <GameCard :id="game.id" :name="game.name" :cover-url="game.coverUrl ?? null" />
        </div>
      </div>

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
import { GET_GENRE } from "@/graphql/queries/resources";
import { DELETE_GENRE } from "@/graphql/mutations/resources";
import { extractGqlError } from "@/utils/graphql-errors";
import type { GetGenreQuery, DeleteGenreMutation } from "@/types/graphql";
import GameCard from "@/components/GameCard.vue";
import ConfirmDialog from "@/components/ConfirmDialog.vue";

const route = useRoute("genre");
const router = useRouter();
const authStore = useAuthStore();
const { show: showSnackbar } = useSnackbar();

const { data, loading, error } = useQuery<GetGenreQuery>(GET_GENRE, {
  variables: { id: route.params.id }
});

watch([data, error, loading], () => {
  if (!loading.value && (error.value || (data.value && !data.value.genre))) {
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
