<template>
  <div>
    <section class="home-section hero">
      <!-- 3D cover mosaic background -->
      <div class="cover-scene">
        <div class="cover-mosaic">
          <div
            v-for="row in mosaicRows"
            :key="row.id"
            class="mosaic-row"
            :class="{ 'mosaic-row-reverse': row.reverse }"
            :style="{ animationDuration: row.speed + 's', animationDelay: row.delay + 's' }"
          >
            <!-- Original tiles -->
            <div
              v-for="tile in row.tiles"
              :key="tile.id"
              class="cover-tile"
              :class="{ flipping: tile.flipping }"
            >
              <div class="tile-face" :style="tile.style"></div>
            </div>
            <!-- Duplicate tiles for seamless loop -->
            <div
              v-for="tile in row.tiles"
              :key="'dup-' + tile.id"
              class="cover-tile"
              :class="{ flipping: tile.flipping }"
            >
              <div class="tile-face" :style="tile.style"></div>
            </div>
          </div>
        </div>
      </div>

      <!-- Gradient overlays for readability -->
      <div class="hero-overlay"></div>
      <div class="hero-fade-top"></div>
      <div class="hero-fade-bottom"></div>

      <!-- Hero content -->
      <div class="hero-body has-text-centered hero-content">
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
import { ref, computed, watch, onMounted, onUnmounted } from "vue";
import { useQuery } from "@/composables/useGraphQL";
import { GET_BASIC_SITE_STATISTICS } from "@/graphql/queries/resources";
import { GET_RECENT_GAMES, GET_HERO_COVERS } from "@/graphql/queries/games";

// ── Existing queries (unchanged) ──

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
  const s = (statsData.value as { basicSiteStatistics: Record<string, number> }).basicSiteStatistics;
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
  return (recentGamesData.value as { games: { nodes: GameNode[] } }).games.nodes;
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

// ── 3D Cover Mosaic ──

const COLS_PER_ROW = 20;
const ROWS = 14;
const TOTAL = COLS_PER_ROW * ROWS;

const PALETTES: [string, string][] = [
  ["#c0392b", "#7b241c"],
  ["#2980b9", "#1a4f72"],
  ["#27ae60", "#145a32"],
  ["#8e44ad", "#4a235a"],
  ["#d35400", "#7e3300"],
  ["#16a085", "#0e6655"],
  ["#2c3e50", "#1a252f"],
  ["#e74c3c", "#922b21"],
  ["#3498db", "#1f618d"],
  ["#1abc9c", "#117a65"],
  ["#9b59b6", "#6c3483"],
  ["#e67e22", "#af601a"],
  ["#34495e", "#1c2833"],
  ["#f39c12", "#b7950b"],
  ["#e84393", "#a31f62"],
  ["#00b894", "#00755b"],
  ["#6c5ce7", "#4834a0"],
  ["#fd79a8", "#c44a72"],
  ["#0984e3", "#065a9e"],
  ["#636e72", "#3d4547"],
  ["#74b9ff", "#4a8ac7"],
  ["#a29bfe", "#7068c4"],
  ["#55efc4", "#38a88a"],
  ["#ff7675", "#c45a59"],
  ["#e17055", "#a8503c"],
  ["#00cec9", "#009b96"],
  ["#b8e994", "#82a668"],
  ["#4a69bd", "#33498a"],
  ["#b71540", "#7e0e2c"],
  ["#079992", "#056b66"],
  ["#38ada9", "#277a77"],
  ["#fa983a", "#c47a2e"],
  ["#78e08f", "#55a06a"],
  ["#f6b93b", "#c4922f"],
  ["#60a3bc", "#4a8295"]
];

interface MosaicTile {
  id: number;
  style: Record<string, string>;
  flipping: boolean;
}

function gradientStyle(index: number): Record<string, string> {
  const row = Math.floor(index / COLS_PER_ROW);
  const col = index % COLS_PER_ROW;
  const pIdx = (row * 7 + col * 3 + row * col) % PALETTES.length;
  const angle = 110 + ((col * 19 + row * 29) % 70);
  return { background: `linear-gradient(${angle}deg, ${PALETTES[pIdx][0]}, ${PALETTES[pIdx][1]})` };
}

function coverStyle(url: string): Record<string, string> {
  return { backgroundImage: `url(${url})`, backgroundSize: "cover", backgroundPosition: "center" };
}

// Start with all gradient tiles (instant render before covers load)
const mosaicTiles = ref<MosaicTile[]>(
  Array.from({ length: TOTAL }, (_, i) => ({
    id: i,
    style: gradientStyle(i),
    flipping: false
  }))
);

// Compute rows from flat tile array — each row scrolls in alternating directions
const mosaicRows = computed(() => {
  const rows: { id: number; tiles: MosaicTile[]; reverse: boolean; speed: number; delay: number }[] = [];
  for (let r = 0; r < ROWS; r++) {
    rows.push({
      id: r,
      tiles: mosaicTiles.value.slice(r * COLS_PER_ROW, (r + 1) * COLS_PER_ROW),
      reverse: r % 2 === 1,
      speed: 120 + ((r * 11) % 40), // Vary speed between 120-159s per row
      delay: -(r * 8.5) // Stagger start positions so rows aren't aligned
    });
  }
  return rows;
});

// Fetch cover images
interface HeroCoverNode {
  id: string;
  coverUrl: string | null;
}

const { data: heroData } = useQuery<{ games: { nodes: HeroCoverNode[] } }>(GET_HERO_COVERS);

const coverUrls = computed<string[]>(() => {
  if (!heroData.value) return [];
  return heroData.value.games.nodes.filter((g) => g.coverUrl).map((g) => g.coverUrl as string);
});

// Distribute cover images across tiles when they load
watch(
  coverUrls,
  (urls) => {
    if (urls.length === 0) return;
    const shuffled = [...urls];
    for (let i = shuffled.length - 1; i > 0; i--) {
      const j = Math.floor(Math.random() * (i + 1));
      [shuffled[i], shuffled[j]] = [shuffled[j], shuffled[i]];
    }
    for (let i = 0; i < TOTAL; i++) {
      const row = Math.floor(i / COLS_PER_ROW);
      const col = i % COLS_PER_ROW;
      // Keep ~25% as gradients for visual variety
      const keepGradient = (row * 3 + col * 7 + row * col) % 4 === 0;
      if (!keepGradient && shuffled.length > 0) {
        mosaicTiles.value[i].style = coverStyle(shuffled[i % shuffled.length]);
      }
    }
  },
  { immediate: true }
);

// ── Flip animation system ──

let flipTimer: ReturnType<typeof setInterval> | null = null;

function flipTile() {
  const tiles = mosaicTiles.value;
  const idx = Math.floor(Math.random() * tiles.length);
  const tile = tiles[idx];
  if (tile.flipping) return;

  tile.flipping = true;

  // Swap background at the midpoint
  setTimeout(() => {
    const urls = coverUrls.value;
    if (urls.length > 0 && Math.random() > 0.2) {
      tile.style = coverStyle(urls[Math.floor(Math.random() * urls.length)]);
    } else {
      const newIdx = Math.floor(Math.random() * PALETTES.length);
      const angle = 110 + Math.floor(Math.random() * 70);
      tile.style = { background: `linear-gradient(${angle}deg, ${PALETTES[newIdx][0]}, ${PALETTES[newIdx][1]})` };
    }
  }, 700);

  setTimeout(() => {
    tile.flipping = false;
  }, 1400);
}

function scheduleFlips() {
  const count = 5 + Math.floor(Math.random() * 4); // 5-8 flips per batch
  for (let i = 0; i < count; i++) {
    setTimeout(flipTile, i * 150 + Math.random() * 250);
  }
}

onMounted(() => {
  setTimeout(() => {
    scheduleFlips();
    flipTimer = setInterval(scheduleFlips, 1200); // Flip batches every 1.2s
  }, 800);
});

onUnmounted(() => {
  if (flipTimer) clearInterval(flipTimer);
});
</script>

<style scoped>
/* ── Hero section ── */
.home-section.hero {
  overflow: hidden;
  background: #110b24;
  min-height: 500px;
  display: flex;
  align-items: center;
  justify-content: center;
}

/* ── 3D scene ── */
.cover-scene {
  position: absolute;
  inset: 0;
  perspective: 410px;
  perspective-origin: 50% 12%;
  pointer-events: none;
  overflow: hidden;
}

.cover-mosaic {
  position: absolute;
  top: -45%;
  left: -50%;
  transform: rotateX(12deg) rotateZ(-23deg);
  transform-style: preserve-3d;
  opacity: 0.59;
  display: flex;
  flex-direction: column;
  gap: 10px;
}

/* ── Row-based scrolling ── */
.mosaic-row {
  display: flex;
  gap: 10px;
  animation: rowScrollLeft 80s linear infinite;
}

.mosaic-row-reverse {
  animation-name: rowScrollRight;
}

@keyframes rowScrollLeft {
  from {
    transform: translateX(0);
  }
  to {
    transform: translateX(-50%);
  }
}

@keyframes rowScrollRight {
  from {
    transform: translateX(-50%);
  }
  to {
    transform: translateX(0);
  }
}

/* ── Tile with flip ── */
.cover-tile {
  flex: 0 0 110px;
  aspect-ratio: 3 / 4;
  border-radius: 5px;
  position: relative;
  transform-style: preserve-3d;
}

.cover-tile.flipping {
  animation: flipCard 1.4s ease-in-out;
}

@keyframes flipCard {
  0% {
    transform: rotateY(0deg) scale(1);
  }
  25% {
    transform: rotateY(90deg) scale(1.05);
  }
  50% {
    transform: rotateY(180deg) scale(1);
  }
  75% {
    transform: rotateY(270deg) scale(1.05);
  }
  100% {
    transform: rotateY(360deg) scale(1);
  }
}

.tile-face {
  position: absolute;
  inset: 0;
  border-radius: 5px;
  background-size: cover;
  background-position: center;
  box-shadow:
    0 1px 6px rgba(0, 0, 0, 0.3),
    0 0 0 1px rgba(255, 255, 255, 0.03);
}

/* ── Overlays ── */
.hero-overlay {
  position: absolute;
  inset: 0;
  background: radial-gradient(
    ellipse 75% 60% at 50% 45%,
    rgba(89, 87, 214, 0.4) 0%,
    rgba(45, 28, 110, 0.7) 45%,
    rgba(17, 11, 36, 0.97) 100%
  );
  pointer-events: none;
  z-index: 1;
}

.hero-fade-bottom {
  position: absolute;
  bottom: 0;
  left: 0;
  right: 0;
  height: 100px;
  background: linear-gradient(to top, var(--bulma-background, #f4f3f7) 0%, transparent 100%);
  pointer-events: none;
  z-index: 1;
}

.hero-fade-top {
  position: absolute;
  top: 0;
  left: 0;
  right: 0;
  height: 70px;
  background: linear-gradient(to bottom, rgba(17, 11, 36, 0.8) 0%, transparent 100%);
  pointer-events: none;
  z-index: 1;
}

/* ── Hero content (above overlays) ── */
.hero-content {
  position: relative;
  z-index: 2;
  padding-top: 5rem;
  padding-bottom: 3rem;
}

/* ── Stats bar ── */
.home-stats-bar {
  margin-top: 2rem;
}

.home-stats-container {
  display: inline-flex;
  gap: 0;
  background: rgba(255, 255, 255, 0.08);
  backdrop-filter: blur(12px);
  -webkit-backdrop-filter: blur(12px);
  border: 1px solid rgba(255, 255, 255, 0.1);
  border-radius: 14px;
  padding: 0.15rem;
}

.home-stat {
  display: block;
  padding: 0.85rem 1.5rem;
  text-align: center;
  text-decoration: none;
  border-radius: 10px;
  transition: background 0.15s;
}

.home-stat:hover {
  background: rgba(255, 255, 255, 0.12);
}

.home-stat-value {
  font-size: 1.6rem;
  font-weight: 700;
  color: #fff;
  line-height: 1.2;
}

.home-stat-label {
  font-size: 0.65rem;
  font-weight: 600;
  letter-spacing: 0.1em;
  color: rgba(255, 255, 255, 0.45);
  margin-top: 0.15rem;
}

/* ── Game cards ── */
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

/* ── Responsive ── */
@media (max-width: 900px) {
  .home-section.hero {
    min-height: 420px;
  }
  .home-stat {
    padding: 0.7rem 1rem;
  }
  .home-stat-value {
    font-size: 1.3rem;
  }
}

@media (max-width: 600px) {
  .home-section.hero {
    min-height: 380px;
  }
  .home-stats-container {
    flex-wrap: wrap;
    border-radius: 12px;
  }
  .home-stat {
    flex: 1 1 33%;
    min-width: 80px;
  }
}
</style>
