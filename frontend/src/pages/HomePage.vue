<template>
  <div>
    <section class="home-section hero">
      <div class="hero-body has-text-centered">
        <img src="@/assets/images/vglist-logo.svg" alt="vglist" class="home-logo" />
        <p class="subtitle is-4">
          Track your entire video game library across every store and platform.
        </p>

        <div v-if="statsData" class="home-stats-bar">
          <div class="home-stats-container">
            <router-link class="home-stat" v-for="stat in stats" :key="stat.label" :to="stat.path">
              <p class="home-stat-value">{{ stat.value.toLocaleString() }}</p>
              <p class="home-stat-label">{{ stat.label }}</p>
            </router-link>
          </div>
        </div>
      </div>
    </section>

    <section class="section" v-if="recentGamesData">
      <h2 class="title is-4">Recently Added Games</h2>

      <div class="columns is-multiline">
        <div v-for="game in recentGames" :key="game.id" class="column is-4">
          <router-link :to="`/games/${game.id}`" class="home-game-card">
            <div class="media">
              <div class="media-left">
                <figure class="image" style="width: 100px">
                  <img v-if="game.coverUrl" :src="game.coverUrl" :alt="game.name" />
                  <div v-else class="home-cover-placeholder">
                    <span>{{ gameInitials(game.name) }}</span>
                  </div>
                </figure>
              </div>
              <div class="media-content">
                <p class="title is-5">{{ game.name }}</p>
                <p class="subtitle is-6 has-text-grey" v-if="platformNames(game)">
                  {{ platformNames(game) }}
                </p>
                <p class="is-size-7 has-text-grey" v-if="developerNames(game)">
                  {{ developerNames(game) }}
                </p>
              </div>
            </div>
          </router-link>
        </div>
      </div>
    </section>
  </div>
</template>

<script setup lang="ts">
import { computed } from "vue";
import { useQuery } from "@/composables/useGraphQL";
import { GET_BASIC_SITE_STATISTICS } from "@/graphql/queries/resources";
import { GET_RECENT_GAMES } from "@/graphql/queries/games";

const { data: statsData } = useQuery(GET_BASIC_SITE_STATISTICS);
const { data: recentGamesData } = useQuery(GET_RECENT_GAMES, {
  variables: { first: 6 }
});

interface GameNode {
  id: string;
  name: string;
  coverUrl: string | null;
  platforms: { nodes: { id: string; name: string }[] };
  developers: { nodes: { id: string; name: string }[] };
}

const stats = computed(() => {
  if (!statsData.value) return [];
  const s = statsData.value.basicSiteStatistics;
  return [
    { label: "GAMES", value: s.games, path: "/games" },
    { label: "SERIES", value: s.series, path: "/series" },
    { label: "PLATFORMS", value: s.platforms, path: "/platforms" },
    { label: "COMPANIES", value: s.companies, path: "/companies" },
    { label: "ENGINES", value: s.engines, path: "/engines" },
    { label: "GENRES", value: s.genres, path: "/genres" }
  ];
});

const recentGames = computed(() => {
  if (!recentGamesData.value) return [];
  return recentGamesData.value.games.nodes as GameNode[];
});

function gameInitials(name: string): string {
  return name
    .split(/[\s:]+/)
    .filter((w) => w.length > 0)
    .slice(0, 3)
    .map((w) => w[0].toUpperCase())
    .join("");
}

function platformNames(game: GameNode): string {
  const names = game.platforms.nodes.map((p) => p.name);
  if (names.length <= 3) return names.join(", ");
  return `${names.slice(0, 2).join(", ")}, and ${names.length - 2} more`;
}

function developerNames(game: GameNode): string {
  return game.developers.nodes.map((d) => d.name).join(", ");
}
</script>

<style scoped>
.home-stats-bar {
  margin-top: 2rem;
}

.home-stats-container {
  display: inline-flex;
  gap: 0;
  background: rgba(255, 255, 255, 0.15);
  border-radius: 8px;
  padding: 1rem 2rem;
  backdrop-filter: blur(4px);
}

.home-stat {
  display: block;
  padding: 0.5rem 1.5rem;
  text-align: center;
  text-decoration: none;
  border-radius: 6px;
  transition: background 0.15s;
}

.home-stat:hover {
  background: rgba(255, 255, 255, 0.12);
}

.home-stat-value {
  font-size: 1.75rem;
  font-weight: 700;
  color: #fff;
  line-height: 1.2;
}

.home-stat-label {
  font-size: 0.7rem;
  font-weight: 600;
  letter-spacing: 0.05em;
  color: hsl(210, 100%, 75%);
}

.home-game-card {
  display: block;
  padding: 1rem;
  border: 1px solid hsl(0, 0%, 90%);
  border-radius: 6px;
  color: inherit;
  transition: box-shadow 0.15s;
  height: 100%;
}

.home-game-card:hover {
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.1);
}

.home-game-card .title {
  margin-bottom: 0.25rem;
}

.home-game-card .subtitle {
  margin-bottom: 0.25rem;
}

.home-cover-placeholder {
  width: 100%;
  aspect-ratio: 3 / 4;
  background: linear-gradient(135deg, #e879a0 0%, #c266d6 50%, #7c5ce7 100%);
  border-radius: 4px;
  display: flex;
  align-items: center;
  justify-content: center;
}

.home-cover-placeholder span {
  font-size: 1.5rem;
  font-weight: 700;
  color: #fff;
  letter-spacing: 0.05em;
}
</style>
