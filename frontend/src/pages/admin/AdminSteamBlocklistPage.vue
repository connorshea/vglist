<template>
  <div>
    <div class="mb-4">
      <form class="field is-grouped" @submit.prevent="addSteamBlocklistEntry">
        <div class="control">
          <input v-model="newSteamName" class="input" type="text" placeholder="Game name" required />
        </div>
        <div class="control">
          <input
            v-model.number="newSteamAppId"
            class="input"
            type="number"
            placeholder="Steam App ID"
            required
            min="1"
          />
        </div>
        <div class="control">
          <button class="button is-primary" type="submit">Add to blocklist</button>
        </div>
      </form>
    </div>

    <div v-if="!sbLoaded && sbLoading" class="has-text-centered py-6">Loading...</div>
    <div v-if="sbError" class="notification is-danger">{{ sbError }}</div>

    <template v-if="sbLoaded">
      <div class="table-container">
        <table class="table is-fullwidth is-striped">
          <thead>
            <tr>
              <th>Steam App ID</th>
              <th>Game Name</th>
              <th>Created by</th>
              <th></th>
            </tr>
          </thead>
          <tbody>
            <tr v-for="entry in sbEntries" :key="entry.id">
              <td>
                <a
                  :href="`https://store.steampowered.com/app/${entry.steamAppId}`"
                  target="_blank"
                  rel="noopener noreferrer"
                >
                  {{ entry.steamAppId }}
                </a>
              </td>
              <td>{{ entry.name }}</td>
              <td>
                <router-link v-if="entry.user" :to="`/users/${entry.user.slug}`">
                  {{ entry.user.username }}
                </router-link>
              </td>
              <td>
                <button class="button is-small is-danger is-outlined" @click="removeFromSteamBlocklist(entry.id)">
                  Remove
                </button>
              </td>
            </tr>
          </tbody>
        </table>
      </div>
      <AdminLoadMore
        :has-next-page="sbHasNextPage"
        :loading="sbLoadingMore"
        :error="sbLoadMoreError"
        noun="entries"
        @load-more="sbLoadMore"
      />
      <p v-if="sbEntries.length === 0" class="has-text-centered has-text-grey py-4">
        No entries in the Steam blocklist.
      </p>
    </template>
  </div>
</template>

<script setup lang="ts">
import { ref, watch } from "vue";
import { useRoute, useRouter } from "vue-router";
import AdminLoadMore from "@/components/admin/AdminLoadMore.vue";
import { useConnectionList } from "@/composables/useConnectionList";
import { useSnackbar } from "@/composables/useSnackbar";
import { gqlClient } from "@/graphql/client";
import { GET_STEAM_BLOCKLIST } from "@/graphql/queries/admin";
import { ADD_TO_STEAM_BLOCKLIST, REMOVE_FROM_STEAM_BLOCKLIST } from "@/graphql/mutations/admin";
import { extractGqlError } from "@/utils/graphql-errors";
import type { GetSteamBlocklistQuery } from "@/types/graphql";

const { show: showSnackbar } = useSnackbar();
const route = useRoute();
const router = useRouter();

const {
  nodes: sbEntries,
  loaded: sbLoaded,
  loading: sbLoading,
  error: sbError,
  hasNextPage: sbHasNextPage,
  loadMore: sbLoadMore,
  loadingMore: sbLoadingMore,
  loadMoreError: sbLoadMoreError,
  reload: sbRefetch
} = useConnectionList(GET_STEAM_BLOCKLIST, {
  select: (data: GetSteamBlocklistQuery) => data.steamBlocklist
});

const newSteamName = ref("");
const newSteamAppId = ref<number | undefined>(undefined);

// Prefill the form from `?name=…&steamAppId=…`, e.g.
// `/admin/steam-blocklist?name=Half-Life+OST&steamAppId=12345`.
watch(
  () => [route.query.name, route.query.steamAppId] as const,
  ([name, steamAppId]) => {
    if (typeof name === "string" && name !== "") newSteamName.value = name;
    if (typeof steamAppId === "string" && /^[1-9]\d*$/.test(steamAppId)) {
      newSteamAppId.value = Number(steamAppId);
    }
  },
  { immediate: true }
);

async function addSteamBlocklistEntry() {
  if (!newSteamName.value || !newSteamAppId.value) return;
  try {
    await gqlClient.request(ADD_TO_STEAM_BLOCKLIST, {
      name: newSteamName.value,
      steamAppId: newSteamAppId.value
    });
    showSnackbar("Added to Steam blocklist.");
    newSteamName.value = "";
    newSteamAppId.value = undefined;
    // Drop any prefill params so a reload doesn't refill the form.
    if (route.query.name !== undefined || route.query.steamAppId !== undefined) {
      router.replace({ query: {} });
    }
    sbRefetch();
  } catch (err) {
    showSnackbar(extractGqlError(err), "error");
  }
}

async function removeFromSteamBlocklist(id: string) {
  try {
    await gqlClient.request(REMOVE_FROM_STEAM_BLOCKLIST, { steamBlocklistEntryId: id });
    showSnackbar("Removed from Steam blocklist.");
    sbRefetch();
  } catch (err) {
    showSnackbar(extractGqlError(err), "error");
  }
}
</script>
