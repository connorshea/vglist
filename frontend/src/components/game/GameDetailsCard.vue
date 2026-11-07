<template>
  <section class="game-card" aria-labelledby="game-details-heading">
    <h2 id="game-details-heading" class="game-card-label">Details</h2>
    <dl v-if="hasDetails" class="details-list">
      <template v-if="game.releaseDate">
        <dt>Released</dt>
        <dd>{{ formatReleaseDate(game.releaseDate) }}</dd>
      </template>
      <template v-if="game.developers.nodes.length">
        <dt>{{ game.developers.nodes.length === 1 ? "Developer" : "Developers" }}</dt>
        <dd><LinkedNames :items="game.developers.nodes" base="/companies" /></dd>
      </template>
      <template v-if="game.publishers.nodes.length">
        <dt>{{ game.publishers.nodes.length === 1 ? "Publisher" : "Publishers" }}</dt>
        <dd><LinkedNames :items="game.publishers.nodes" base="/companies" /></dd>
      </template>
      <template v-if="game.engines.nodes.length">
        <dt>{{ game.engines.nodes.length === 1 ? "Engine" : "Engines" }}</dt>
        <dd><LinkedNames :items="game.engines.nodes" base="/engines" /></dd>
      </template>
      <template v-if="game.series">
        <dt>Series</dt>
        <dd>
          <router-link :to="`/series/${game.series.id}`">{{ game.series.name }}</router-link>
        </dd>
      </template>
      <template v-if="game.platforms.nodes.length">
        <dt>{{ game.platforms.nodes.length === 1 ? "Platform" : "Platforms" }}</dt>
        <dd><LinkedNames :items="game.platforms.nodes" base="/platforms" /></dd>
      </template>
      <template v-if="game.genres.nodes.length">
        <dt>{{ game.genres.nodes.length === 1 ? "Genre" : "Genres" }}</dt>
        <dd><LinkedNames :items="game.genres.nodes" base="/genres" /></dd>
      </template>
    </dl>
    <p v-else class="game-card-empty">No details yet.</p>
  </section>
</template>

<script setup lang="ts">
import { computed } from "vue";
import LinkedNames from "@/components/game/LinkedNames.vue";

interface NamedNode {
  id: string;
  name: string;
}

export interface GameDetails {
  releaseDate?: string | null;
  developers: { nodes: NamedNode[] };
  publishers: { nodes: NamedNode[] };
  engines: { nodes: NamedNode[] };
  platforms: { nodes: NamedNode[] };
  genres: { nodes: NamedNode[] };
  series?: NamedNode | null;
}

const props = defineProps<{ game: GameDetails }>();

const hasDetails = computed(() => {
  const g = props.game;
  return Boolean(
    g.releaseDate ||
    g.series ||
    g.developers.nodes.length ||
    g.publishers.nodes.length ||
    g.engines.nodes.length ||
    g.platforms.nodes.length ||
    g.genres.nodes.length
  );
});

// Release dates are ISO dates with no time, so parse them as UTC to keep the
// day from shifting in timezones west of UTC.
function formatReleaseDate(date: string): string {
  return new Date(`${date.slice(0, 10)}T00:00:00Z`).toLocaleDateString("en-US", {
    year: "numeric",
    month: "long",
    day: "numeric",
    timeZone: "UTC"
  });
}
</script>

<style scoped>
.details-list {
  display: grid;
  grid-template-columns: auto minmax(0, 1fr);
  gap: 8px 16px;
  margin: 0;
  font-size: 0.875rem;
}

.details-list dt {
  color: var(--color-text-secondary);
}

.details-list dd {
  margin: 0;
  color: var(--color-text-primary);
}

.details-list :deep(a) {
  color: var(--color-accent);
}

.details-list :deep(a:hover) {
  text-decoration: underline;
}
</style>
