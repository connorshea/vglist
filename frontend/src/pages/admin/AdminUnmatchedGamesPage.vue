<template>
  <div>
    <div v-if="ugLoading" class="has-text-centered py-6">Loading...</div>
    <div v-if="ugError" class="notification is-danger">{{ ugError.message }}</div>

    <template v-if="ugData">
      <div class="table-container">
        <table class="table is-fullwidth is-striped is-narrow">
          <thead>
            <tr>
              <th>Count</th>
              <th>Service</th>
              <th>Service ID</th>
              <th>Game Name</th>
              <th>Wikidata</th>
              <th>Actions</th>
            </tr>
          </thead>
          <tbody>
            <tr v-for="game in ugData.groupedUnmatchedGames?.nodes" :key="game.externalServiceId">
              <td>{{ game.count }}</td>
              <td>{{ game.externalServiceName }}</td>
              <td>
                <a
                  v-if="game.externalServiceName === 'STEAM'"
                  :href="`https://store.steampowered.com/app/${game.externalServiceId}`"
                  target="_blank"
                  rel="noopener noreferrer"
                >
                  {{ game.externalServiceId }}
                </a>
                <template v-else>{{ game.externalServiceId }}</template>
              </td>
              <td>{{ game.name }}</td>
              <td>
                <a
                  :href="`https://www.wikidata.org/w/index.php?search=${encodeURIComponent(game.name)}`"
                  target="_blank"
                  rel="noopener noreferrer"
                  class="mr-2"
                >
                  Search
                </a>
                <a
                  :href="`https://www.wikidata.org/w/index.php?title=Special:NewItem&label=${encodeURIComponent(game.name)}&description=video+game`"
                  target="_blank"
                  rel="noopener noreferrer"
                >
                  Create
                </a>
              </td>
              <td>
                <button
                  class="button is-small is-danger is-outlined"
                  @click="removeUnmatchedGame(game.externalServiceId, game.externalServiceName)"
                >
                  Delete
                </button>
              </td>
            </tr>
          </tbody>
        </table>
      </div>
      <p v-if="ugData.groupedUnmatchedGames?.nodes.length === 0" class="has-text-centered has-text-grey py-4">
        No unmatched games.
      </p>
    </template>
  </div>
</template>

<script setup lang="ts">
import { useQuery } from "@/composables/useGraphQL";
import { useSnackbar } from "@/composables/useSnackbar";
import { gqlClient } from "@/graphql/client";
import { GET_UNMATCHED_GAMES } from "@/graphql/queries/admin";
import { REMOVE_FROM_UNMATCHED_GAMES } from "@/graphql/mutations/admin";
import { extractGqlError } from "@/utils/graphql-errors";
import type { GetUnmatchedGamesQuery } from "@/types/graphql";

const { show: showSnackbar } = useSnackbar();

const {
  data: ugData,
  loading: ugLoading,
  error: ugError,
  refetch: ugRefetch
} = useQuery<GetUnmatchedGamesQuery>(GET_UNMATCHED_GAMES, { variables: { first: 50 } });

async function removeUnmatchedGame(externalServiceId: string, externalServiceName: string) {
  try {
    await gqlClient.request(REMOVE_FROM_UNMATCHED_GAMES, { externalServiceId, externalServiceName });
    showSnackbar("Unmatched game removed.");
    ugRefetch();
  } catch (err) {
    showSnackbar(extractGqlError(err), "error");
  }
}
</script>
