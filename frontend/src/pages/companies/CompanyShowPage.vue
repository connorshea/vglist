<template>
  <section class="section">
    <div v-if="loading && !data" class="has-text-centered">
      <p>Loading company...</p>
    </div>

    <div v-if="error" class="notification is-danger">
      <p>Failed to load company: {{ error.message }}</p>
    </div>

    <div v-if="data?.company">
      <h1 class="title">{{ data.company.name }}</h1>

      <!-- TODO: Figure out how to do this without the style tag. -->
      <p v-if="data.company.wikidataId" class="subtitle is-6" style="margin-bottom: 1.5rem">
        <a :href="`https://www.wikidata.org/wiki/Q${data.company.wikidataId}`" target="_blank" rel="noopener noreferrer"
          >Wikidata</a
        >
      </p>

      <div v-if="authStore.isModerator" class="buttons">
        <router-link :to="`/companies/${data.company.id}/edit`" class="button is-small">Edit</router-link>
        <button class="button is-small is-danger is-light" @click="showDeleteConfirm = true">Delete</button>
      </div>

      <div v-if="data.company.developedGames.nodes.length" class="mb-6">
        <h2 class="title is-4">Developed Games</h2>

        <div class="columns is-multiline">
          <div v-for="game in data.company.developedGames.nodes" :key="game.id" class="column is-2">
            <GameCard :id="game.id" :name="game.name" :cover-url="game.coverUrl ?? null" />
          </div>
        </div>
      </div>

      <!-- TODO: Figure out how to do this without the style tag. -->
      <div v-if="data.company.publishedGames.nodes.length" class="mb-6" style="margin-top: 2.5rem">
        <h2 class="title is-4">Published Games</h2>

        <div class="columns is-multiline">
          <div v-for="game in data.company.publishedGames.nodes" :key="game.id" class="column is-2">
            <GameCard :id="game.id" :name="game.name" :cover-url="game.coverUrl ?? null" />
          </div>
        </div>
      </div>

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
import { GET_COMPANY } from "@/graphql/queries/resources";
import { DELETE_COMPANY } from "@/graphql/mutations/resources";
import { extractGqlError } from "@/utils/graphql-errors";
import type { GetCompanyQuery, DeleteCompanyMutation } from "@/types/graphql";
import GameCard from "@/components/GameCard.vue";
import ConfirmDialog from "@/components/ConfirmDialog.vue";

const route = useRoute("company");
const router = useRouter();
const authStore = useAuthStore();
const { show: showSnackbar } = useSnackbar();

const { data, loading, error } = useQuery<GetCompanyQuery>(GET_COMPANY, {
  variables: { id: route.params.id }
});

watch([data, error, loading], () => {
  if (!loading.value && (error.value || (data.value && !data.value.company))) {
    router.replace({ name: "notFound" });
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
