<template>
  <div class="column is-8">
    <!-- Rating -->
    <div v-if="game.avgRating" class="game-rating">
      <div class="rating-circle-wrapper">
        <svg class="rating-circle-svg" viewBox="0 0 120 120">
          <circle class="rating-circle-bg" cx="60" cy="60" r="52" fill="none" stroke-width="5" />
          <circle
            cx="60"
            cy="60"
            r="52"
            fill="none"
            stroke="var(--vglist-theme)"
            stroke-width="5"
            :stroke-dasharray="ratingCircumference"
            :stroke-dashoffset="ratingOffset"
            stroke-linecap="round"
            transform="rotate(-90 60 60)"
          />
        </svg>
        <span class="rating-circle-value">{{ Math.round(game.avgRating) }}</span>
      </div>

      <div class="rating-bar-area">
        <div class="rating-bar-header">
          <span>Average rating</span>
          <span>{{ game.avgRating.toFixed(1) }} / 100</span>
        </div>
        <div class="rating-bar-track">
          <div class="rating-bar-fill" :style="{ width: game.avgRating + '%' }"></div>
        </div>
      </div>
    </div>

    <!-- Details -->
    <h3 class="details-heading">DETAILS</h3>
    <div class="details-grid">
      <div v-if="game.releaseDate" class="detail-card">
        <span class="detail-label">RELEASE DATE</span>
        <span class="detail-value">{{ formatDate(game.releaseDate) }}</span>
      </div>
      <div v-if="game.publishers.nodes.length" class="detail-card">
        <span class="detail-label">PUBLISHER</span>
        <span class="detail-value">
          <template v-for="(pub, i) in game.publishers.nodes" :key="pub.id">
            <router-link :to="`/companies/${pub.id}`" class="detail-link">{{ pub.name }}</router-link>
            <span v-if="i < game.publishers.nodes.length - 1">, </span>
          </template>
        </span>
      </div>
      <div v-if="game.developers.nodes.length" class="detail-card">
        <span class="detail-label">DEVELOPERS</span>
        <span class="detail-value">
          <template v-for="(dev, i) in game.developers.nodes" :key="dev.id">
            <router-link :to="`/companies/${dev.id}`" class="detail-link">{{ dev.name }}</router-link>
            <span v-if="i < game.developers.nodes.length - 1">, </span>
          </template>
        </span>
      </div>
      <div v-if="game.engines.nodes.length" class="detail-card">
        <span class="detail-label">ENGINE</span>
        <span class="detail-value">
          <template v-for="(eng, i) in game.engines.nodes" :key="eng.id">
            <router-link :to="`/engines/${eng.id}`" class="detail-link">{{ eng.name }}</router-link>
            <span v-if="i < game.engines.nodes.length - 1">, </span>
          </template>
        </span>
      </div>
      <div v-if="game.series" class="detail-card">
        <span class="detail-label">SERIES</span>
        <span class="detail-value">
          <router-link :to="`/series/${game.series.id}`" class="detail-link">{{ game.series.name }}</router-link>
        </span>
      </div>
      <div v-if="game.platforms.nodes.length" class="detail-card">
        <span class="detail-label">PLATFORM</span>
        <span class="detail-value">
          <template v-for="(plat, i) in game.platforms.nodes" :key="plat.id">
            <router-link :to="`/platforms/${plat.id}`" class="detail-link">{{ plat.name }}</router-link>
            <span v-if="i < game.platforms.nodes.length - 1">, </span>
          </template>
        </span>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { computed } from "vue";

interface NamedNode {
  id: string;
  name: string;
}

interface GameDetails {
  avgRating?: number | null;
  releaseDate?: string | null;
  publishers: { nodes: NamedNode[] };
  developers: { nodes: NamedNode[] };
  engines: { nodes: NamedNode[] };
  platforms: { nodes: NamedNode[] };
  series?: { id: string; name: string } | null;
}

const props = defineProps<{
  game: GameDetails;
}>();

const CIRCLE_RADIUS = 52;
const ratingCircumference = 2 * Math.PI * CIRCLE_RADIUS;

const ratingOffset = computed(() => {
  if (!props.game.avgRating) return ratingCircumference;
  const pct = props.game.avgRating / 100;
  return ratingCircumference * (1 - pct);
});

function formatDate(dateStr: string): string {
  const d = new Date(dateStr);
  return d.toLocaleDateString("en-US", { year: "numeric", month: "long", day: "numeric" });
}
</script>

<style scoped>
/* ── Rating section ── */
.game-rating {
  display: flex;
  align-items: center;
  gap: 1.5rem;
  margin-bottom: 2.5rem;
}

.rating-circle-wrapper {
  position: relative;
  width: 80px;
  height: 80px;
  flex-shrink: 0;
}

.rating-circle-svg {
  width: 100%;
  height: 100%;
}

.rating-circle-value {
  position: absolute;
  top: 50%;
  left: 50%;
  transform: translate(-50%, -50%);
  font-size: 1.5rem;
  font-weight: 700;
  color: var(--vglist-theme);
}

.rating-bar-area {
  flex: 1;
}

.rating-circle-bg {
  stroke: var(--game-track-bg);
}

.rating-bar-header {
  display: flex;
  justify-content: space-between;
  margin-bottom: 0.5rem;
  font-size: 0.9rem;
  color: var(--game-text-muted);
}

.rating-bar-track {
  height: 10px;
  background: var(--game-track-bg);
  border-radius: 5px;
  overflow: hidden;
}

.rating-bar-fill {
  height: 100%;
  background: linear-gradient(90deg, var(--p-500), var(--p-400));
  border-radius: 5px;
  transition: width 0.4s ease;
}

/* ── Details ── */
.details-heading {
  font-size: 0.8rem;
  font-weight: 600;
  letter-spacing: 0.1em;
  color: var(--vglist-theme);
  margin-bottom: 1rem;
}

.details-grid {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 1rem;
}

.detail-card {
  border: 1px solid var(--game-border);
  border-radius: var(--radius-md);
  padding: 1rem 1.25rem;
  display: flex;
  flex-direction: column;
  gap: 0.3rem;
}

.detail-label {
  font-size: 0.7rem;
  font-weight: 600;
  letter-spacing: 0.08em;
  color: var(--game-text-label);
  text-transform: uppercase;
}

.detail-value {
  font-size: 1rem;
  font-weight: 500;
  line-height: 1.4;
}

.detail-link {
  color: var(--vglist-theme);
  text-decoration: none;
}

.detail-link:hover {
  text-decoration: underline;
}

@media (prefers-color-scheme: dark) {
  .detail-link {
    color: var(--game-link-color);
  }

  .rating-circle-value {
    color: var(--game-link-color);
  }

  .details-heading {
    color: var(--game-link-color);
  }

  .rating-bar-fill {
    background: var(--p-400);
  }
}

/* ── Responsive ── */
@media (max-width: 768px) {
  .details-grid {
    grid-template-columns: 1fr;
  }
}
</style>
