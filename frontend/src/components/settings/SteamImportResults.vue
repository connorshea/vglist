<template>
  <ImportResults
    id-prefix="steam-results"
    :added-games="result.addedGames"
    :updated-games="result.updatedGames"
    updated-title="Updated hours played"
    :unmatched-games="unmatchedGames"
    :unmatched-note="UNMATCHED_NOTE"
    nothing-changed-message="Everything vglist recognizes from your Steam library is already in your library."
  />
</template>

<script setup lang="ts">
import { computed } from "vue";
import ImportResults from "@/components/settings/ImportResults.vue";
import type { ImportSteamLibraryMutation } from "@/types/graphql";

type ImportResult = NonNullable<ImportSteamLibraryMutation["importSteamLibrary"]>;

const UNMATCHED_NOTE =
  "These games from your Steam library don't match a game on vglist yet. Many are DLC, soundtracks, or alternate " +
  'editions, like a "Game of the Year" release, of games that are already on vglist.';

const props = defineProps<{
  result: ImportResult;
}>();

const unmatchedGames = computed(() =>
  props.result.unmatchedGames.map((game) => ({
    key: String(game.steamAppId),
    name: game.name,
    url: `https://store.steampowered.com/app/${game.steamAppId}`,
    linkLabel: `Steam App ${game.steamAppId}`
  }))
);
</script>
