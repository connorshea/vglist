<template>
  <div>
    <div v-if="wbLoading" class="has-text-centered py-6">Loading...</div>
    <div v-if="wbError" class="notification is-danger">{{ wbError.message }}</div>

    <template v-if="wbData">
      <div class="table-container">
        <table class="table is-fullwidth is-striped">
          <thead>
            <tr>
              <th>Wikidata ID</th>
              <th>Game Name</th>
              <th>Created by</th>
              <th></th>
            </tr>
          </thead>
          <tbody>
            <tr v-for="entry in wbData.wikidataBlocklist?.nodes" :key="entry.id">
              <td>
                <a
                  :href="`https://www.wikidata.org/wiki/Q${entry.wikidataId}`"
                  target="_blank"
                  rel="noopener noreferrer"
                >
                  {{ entry.wikidataId }}
                </a>
              </td>
              <td>{{ entry.name }}</td>
              <td>
                <router-link v-if="entry.user" :to="`/users/${entry.user.slug}`">
                  {{ entry.user.username }}
                </router-link>
              </td>
              <td>
                <button class="button is-small is-danger is-outlined" @click="removeFromWikidataBlocklist(entry.id)">
                  Remove
                </button>
              </td>
            </tr>
          </tbody>
        </table>
      </div>
      <p v-if="wbData.wikidataBlocklist?.nodes.length === 0" class="has-text-centered has-text-grey py-4">
        No entries in the Wikidata blocklist.
      </p>
    </template>
  </div>
</template>

<script setup lang="ts">
import { useQuery } from "@/composables/useGraphQL";
import { useSnackbar } from "@/composables/useSnackbar";
import { gqlClient } from "@/graphql/client";
import { GET_WIKIDATA_BLOCKLIST } from "@/graphql/queries/admin";
import { REMOVE_FROM_WIKIDATA_BLOCKLIST } from "@/graphql/mutations/admin";
import { extractGqlError } from "@/utils/graphql-errors";
import type { GetWikidataBlocklistQuery } from "@/types/graphql";

const { show: showSnackbar } = useSnackbar();

const {
  data: wbData,
  loading: wbLoading,
  error: wbError,
  refetch: wbRefetch
} = useQuery<GetWikidataBlocklistQuery>(GET_WIKIDATA_BLOCKLIST, { variables: { first: 50 } });

async function removeFromWikidataBlocklist(id: string) {
  try {
    await gqlClient.request(REMOVE_FROM_WIKIDATA_BLOCKLIST, { wikidataBlocklistEntryId: id });
    showSnackbar("Removed from Wikidata blocklist.");
    wbRefetch();
  } catch (err) {
    showSnackbar(extractGqlError(err), "error");
  }
}
</script>
