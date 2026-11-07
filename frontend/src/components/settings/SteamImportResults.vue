<template>
  <section class="set-card" aria-labelledby="steam-results-heading">
    <h2 id="steam-results-heading" class="set-card-title">Import results</h2>
    <p class="set-card-desc">What changed in your library from this import.</p>

    <section v-if="result.addedGames.length > 0" class="import-group" aria-labelledby="steam-results-added">
      <h3 id="steam-results-added" class="import-group-title">
        Added to your library <span class="import-count">{{ result.addedGames.length }}</span>
      </h3>
      <ul class="import-games">
        <li v-for="game in visible(result.addedGames, 'added')" :key="game.id">
          <router-link :to="{ name: 'game', params: { id: game.id } }" class="import-game">
            <span class="import-cover">
              <img v-if="game.coverUrl" :src="game.coverUrl" alt="" loading="lazy" />
              <span v-else aria-hidden="true">{{ gameInitials(game.name) }}</span>
            </span>
            <span class="import-game-name">{{ game.name }}</span>
          </router-link>
        </li>
      </ul>
      <ShowAllButton
        v-if="result.addedGames.length > PREVIEW_LIMIT"
        :expanded="expanded.added"
        :total="result.addedGames.length"
        @toggle="expanded.added = !expanded.added"
      />
    </section>

    <section v-if="result.updatedGames.length > 0" class="import-group" aria-labelledby="steam-results-updated">
      <h3 id="steam-results-updated" class="import-group-title">
        Updated hours played <span class="import-count">{{ result.updatedGames.length }}</span>
      </h3>
      <ul class="import-games">
        <li v-for="game in visible(result.updatedGames, 'updated')" :key="game.id">
          <router-link :to="{ name: 'game', params: { id: game.id } }" class="import-game">
            <span class="import-cover">
              <img v-if="game.coverUrl" :src="game.coverUrl" alt="" loading="lazy" />
              <span v-else aria-hidden="true">{{ gameInitials(game.name) }}</span>
            </span>
            <span class="import-game-name">{{ game.name }}</span>
          </router-link>
        </li>
      </ul>
      <ShowAllButton
        v-if="result.updatedGames.length > PREVIEW_LIMIT"
        :expanded="expanded.updated"
        :total="result.updatedGames.length"
        @toggle="expanded.updated = !expanded.updated"
      />
    </section>

    <section v-if="result.unmatchedGames.length > 0" class="import-group" aria-labelledby="steam-results-unmatched">
      <h3 id="steam-results-unmatched" class="import-group-title">
        Couldn't be matched <span class="import-count">{{ result.unmatchedGames.length }}</span>
      </h3>
      <p class="import-note">
        These games from your Steam library don't match a game on vglist yet. Many are DLC, soundtracks, or alternate
        editions, like a "Game of the Year" release, of games that are already on vglist.
      </p>
      <ul class="import-unmatched">
        <li
          v-for="game in visible(result.unmatchedGames, 'unmatched')"
          :key="game.steamAppId"
          class="import-unmatched-row"
        >
          <span class="import-unmatched-body">
            <span class="import-game-name">{{ game.name }}</span>
            <a
              class="import-steam-link"
              :href="`https://store.steampowered.com/app/${game.steamAppId}`"
              target="_blank"
              rel="noopener noreferrer"
            >
              Steam App {{ game.steamAppId }}
              <ExternalLink :size="12" aria-hidden="true" />
              <span class="is-sr-only">(opens in a new tab)</span>
            </a>
          </span>
        </li>
      </ul>
      <ShowAllButton
        v-if="result.unmatchedGames.length > PREVIEW_LIMIT"
        :expanded="expanded.unmatched"
        :total="result.unmatchedGames.length"
        @toggle="expanded.unmatched = !expanded.unmatched"
      />
    </section>

    <p v-if="nothingChanged" class="import-note">
      Everything vglist recognizes from your Steam library is already in your library.
    </p>
  </section>
</template>

<script setup lang="ts">
import { computed, reactive } from "vue";
import { ExternalLink } from "@lucide/vue";
import ShowAllButton from "@/components/settings/ShowAllButton.vue";
import type { ImportSteamLibraryMutation } from "@/types/graphql";
import { gameInitials } from "@/utils/library";

type ImportResult = NonNullable<ImportSteamLibraryMutation["importSteamLibrary"]>;
type Group = "added" | "updated" | "unmatched";

// Long lists start collapsed so a big first import doesn't bury the page.
const PREVIEW_LIMIT = 12;

const props = defineProps<{
  result: ImportResult;
}>();

const expanded = reactive<Record<Group, boolean>>({ added: false, updated: false, unmatched: false });

function visible<T>(items: T[], group: Group): T[] {
  return expanded[group] ? items : items.slice(0, PREVIEW_LIMIT);
}

const nothingChanged = computed(
  () =>
    props.result.addedGames.length === 0 &&
    props.result.updatedGames.length === 0 &&
    props.result.unmatchedGames.length === 0
);
</script>

<style scoped>
.import-group {
  padding-top: 16px;
  border-top: 1px solid var(--color-border);
}

.import-group + .import-group {
  margin-top: 20px;
}

.import-group-title {
  display: flex;
  align-items: center;
  gap: 8px;
  margin: 0 0 12px;
  font-size: 14px;
  font-weight: 600;
  color: var(--color-text-primary);
}

.import-count {
  padding: 1px 8px;
  border-radius: 999px;
  background: var(--color-bg-subtle);
  color: var(--color-text-secondary);
  font-size: 12px;
  font-weight: 500;
}

.import-note {
  margin: 0 0 12px;
  font-size: 13px;
  color: var(--color-text-secondary);
}

.import-games {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(200px, 1fr));
  gap: 4px 12px;
  margin: 0;
  padding: 0;
  list-style: none;
}

.import-game {
  display: flex;
  align-items: center;
  gap: 10px;
  min-width: 0;
  padding: 6px;
  border-radius: var(--radius-sm);
  color: var(--color-text-primary);
}

.import-game:hover {
  background: var(--color-bg-subtle);
}

.import-game:focus-visible {
  outline: 2px solid var(--color-accent);
  outline-offset: 0;
}

.import-cover {
  flex-shrink: 0;
  width: 32px;
  aspect-ratio: 3 / 4;
  overflow: hidden;
  border-radius: 4px;
  display: flex;
  align-items: center;
  justify-content: center;
  background: linear-gradient(135deg, var(--p-300), var(--p-600));
  color: #fff;
  font-size: 10px;
  font-weight: 700;
}

.import-cover img {
  display: block;
  width: 100%;
  height: 100%;
  object-fit: cover;
}

.import-game-name {
  min-width: 0;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
  font-size: 14px;
  font-weight: 500;
}

.import-unmatched {
  margin: 0;
  padding: 0;
  list-style: none;
}

.import-unmatched-row {
  display: flex;
  align-items: center;
  justify-content: space-between;
  flex-wrap: wrap;
  gap: 8px 12px;
  padding: 10px 0;
}

.import-unmatched-row + .import-unmatched-row {
  border-top: 1px solid var(--color-border);
}

.import-unmatched-body {
  display: flex;
  flex-direction: column;
  gap: 2px;
  min-width: 0;
  flex: 1 1 220px;
}

.import-unmatched-body .import-game-name {
  white-space: normal;
  overflow-wrap: anywhere;
}

.import-steam-link {
  display: inline-flex;
  align-items: center;
  gap: 4px;
  width: fit-content;
  font-size: 12px;
  color: var(--color-text-secondary);
}

.import-steam-link:hover {
  color: var(--color-accent);
}

.import-steam-link:focus-visible {
  outline: 2px solid var(--color-accent);
  outline-offset: 2px;
  border-radius: 2px;
}
</style>
