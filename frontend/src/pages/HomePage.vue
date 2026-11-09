<template>
  <div>
    <section class="home-section hero">
      <!-- 3D cover mosaic background -->
      <div class="cover-scene" aria-hidden="true">
        <div class="cover-mosaic" :class="{ 'covers-loaded': coversReady }">
          <div
            v-for="row in mosaicRows"
            :key="row.id"
            class="mosaic-row"
            :class="{ 'mosaic-row-reverse': row.reverse }"
            :style="{ animationDuration: row.speed + 's', animationDelay: row.delay + 's' }"
          >
            <!-- Original tiles -->
            <div v-for="tile in row.tiles" :key="tile.id" class="cover-tile" :class="{ flipping: tile.flipping }">
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
      <div class="hero-content">
        <h1 class="home-heading"><img src="@/assets/images/vglist-logo.svg" alt="vglist" class="home-logo" /></h1>
        <p class="home-lede">Track your entire video game library across every store and platform.</p>

        <!-- Opens the search overlay, carrying over whatever is typed here. -->
        <button
          type="button"
          class="home-search"
          aria-haspopup="dialog"
          @click="openSearch()"
          @keydown="onSearchKeydown"
        >
          <Search :size="20" aria-hidden="true" />
          <span class="home-search-text">{{ searchPlaceholder }}</span>
          <kbd class="home-search-kbd" aria-hidden="true">{{ isMac ? "⌘" : "Ctrl+" }}K</kbd>
        </button>

        <!-- The row keeps its height while the pills load, so nothing below moves. -->
        <div class="home-quick-slot">
          <nav
            v-if="quickLinks.length"
            ref="quickNav"
            class="home-quick"
            aria-label="Browse games by platform or genre"
          >
            <router-link
              v-for="(link, i) in quickLinks"
              :key="link.key"
              :to="link.to"
              class="home-quick-link"
              :class="{ 'is-overflowing': i >= fittingQuickLinks }"
            >
              {{ link.name }}
            </router-link>
          </nav>
          <div v-else-if="!filtersData && !filtersError" class="home-quick">
            <SkeletonBlock
              v-for="(width, i) in QUICK_SKELETON_WIDTHS"
              :key="i"
              class="home-quick-skeleton"
              :style="{ width: `${width}px` }"
            />
          </div>
        </div>
      </div>
    </section>

    <div class="home-body">
      <GameShelf :sort="POPULAR" />

      <aside v-if="!authStore.isAuthenticated" class="home-banner" aria-label="Create an account">
        <span class="home-banner-icon" aria-hidden="true"><LibraryBig :size="20" /></span>
        <p class="home-banner-text">
          <strong>Keep track of your own library.</strong>
          Import from Steam, mark what you’ve finished, and rate what you’ve played.
        </p>
        <router-link to="/signup" class="home-banner-btn">Create an account</router-link>
      </aside>

      <GameShelf :sort="NEW_RELEASES" :rows="2" />
      <GameShelf :sort="UPCOMING_RELEASES" />
      <GameShelf :sort="RECENTLY_ADDED" />

      <p v-if="siteStats" class="home-stats">
        <template v-for="(stat, i) in siteStats" :key="stat.path">
          <template v-if="i > 0"> · </template>
          <router-link :to="stat.path">{{ stat.label }}</router-link>
        </template>
      </p>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, watch, onMounted, onUnmounted } from "vue";
import { LibraryBig, Search } from "@lucide/vue";
import { useQuery } from "@/composables/useGraphQL";
import { useSearchOverlay } from "@/composables/useSearchOverlay";
import { useSaveData } from "@/composables/useSaveData";
import { useAuthStore } from "@/stores/auth";
import { GET_BASIC_SITE_STATISTICS } from "@/graphql/queries/resources";
import { GET_HERO_COVERS } from "@/graphql/queries/games";
import { GET_GAMES_INDEX_FILTERS } from "@/graphql/queries/games-index";
import type { GetBasicSiteStatisticsQuery, GetGamesIndexFiltersQuery } from "@/types/graphql";
import GameShelf from "@/components/home/GameShelf.vue";
import SkeletonBlock from "@/components/SkeletonBlock.vue";
import { countLabel, gameSortFromSlug } from "@/components/games-index/format";

const authStore = useAuthStore();
const { open: openSearch } = useSearchOverlay();

const isMac = navigator.platform.toUpperCase().includes("MAC");

const POPULAR = gameSortFromSlug("popular");
const NEW_RELEASES = gameSortFromSlug("new");
const UPCOMING_RELEASES = gameSortFromSlug("upcoming");
const RECENTLY_ADDED = gameSortFromSlug("added");

// ── Search ──

function onSearchKeydown(e: KeyboardEvent) {
  // Typing straight into the box starts a search with what was typed.
  if (e.key.length === 1 && e.key !== " " && !e.metaKey && !e.ctrlKey && !e.altKey) {
    e.preventDefault();
    openSearch(e.key);
  }
}

const { data: statsData } = useQuery<GetBasicSiteStatisticsQuery>(GET_BASIC_SITE_STATISTICS);

const searchPlaceholder = computed(() => {
  const games = statsData.value?.basicSiteStatistics.games;
  return games ? `Search ${countLabel(games, "game")} and more` : "Search games and more";
});

// ── Quick links: the most common platforms and genres ──

// The games index's own query for its pills, so the home page sends nothing
// new. Its record lookups are switched off.
const { data: filtersData, error: filtersError } = useQuery<GetGamesIndexFiltersQuery>(GET_GAMES_INDEX_FILTERS, {
  variables: {
    platformId: "0",
    hasPlatform: false,
    genreId: "0",
    hasGenre: false,
    engineId: "0",
    hasEngine: false
  }
});

const quickLinks = computed(() => {
  const platforms = (filtersData.value?.platforms?.nodes ?? []).slice(0, 4).map((p) => ({
    key: `platform-${p.id}`,
    name: p.name,
    to: { path: "/games", query: { platform: p.id } }
  }));
  const genres = (filtersData.value?.genres?.nodes ?? []).slice(0, 3).map((g) => ({
    key: `genre-${g.id}`,
    name: g.name,
    to: { path: "/games", query: { genre: g.id } }
  }));
  return [...platforms, ...genres];
});

// Placeholder pill widths while the links load, roughly the real names'.
const QUICK_SKELETON_WIDTHS = [92, 80, 72, 120, 84, 104, 76];

// The pills stay on one row. The row wraps but is one pill tall, so pills that
// would start a second row are cut off; this finds them so they can also be
// taken out of the tab order and the accessibility tree.
const quickNav = ref<HTMLElement | null>(null);
const fittingQuickLinks = ref(Number.POSITIVE_INFINITY);

function fitQuickLinks() {
  const pills = Array.from(quickNav.value?.children ?? []) as HTMLElement[];
  if (pills.length === 0) {
    return;
  }
  const firstRowTop = pills[0].offsetTop;
  const overflowing = pills.findIndex((pill) => pill.offsetTop > firstRowTop);
  fittingQuickLinks.value = overflowing === -1 ? pills.length : overflowing;
}

// Pills change size when the web font arrives, and the row when the window
// does, so watch both.
let quickResizeObserver: ResizeObserver | null = null;

watch(
  quickNav,
  (nav) => {
    quickResizeObserver?.disconnect();
    quickResizeObserver = null;
    if (!nav) {
      return;
    }
    fitQuickLinks();
    if (typeof ResizeObserver === "undefined") {
      return;
    }
    quickResizeObserver = new ResizeObserver(fitQuickLinks);
    quickResizeObserver.observe(nav);
    for (const pill of Array.from(nav.children)) {
      quickResizeObserver.observe(pill);
    }
  },
  { flush: "post" }
);

// ── Site stats, in one line at the bottom ──

const siteStats = computed(() => {
  const s = statsData.value?.basicSiteStatistics;
  if (!s) {
    return null;
  }
  return [
    { label: countLabel(s.games, "game"), path: "/games" },
    { label: countLabel(s.series, "series", "series"), path: "/series" },
    { label: countLabel(s.platforms, "platform"), path: "/platforms" },
    { label: countLabel(s.companies, "company", "companies"), path: "/companies" }
  ];
});

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
  // Set once the tile has flipped, so a cover that finishes loading late
  // doesn't snap over whatever the flip put there.
  flipped: boolean;
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

const coversReady = ref(false);

// Start with all gradient tiles (instant render before covers load)
const mosaicTiles = ref<MosaicTile[]>(
  Array.from({ length: TOTAL }, (_, i) => ({
    id: i,
    style: gradientStyle(i),
    flipping: false,
    flipped: false
  }))
);

// Compute rows from flat tile array — each row scrolls in alternating directions
const mosaicRows = computed(() => {
  const rows: {
    id: number;
    tiles: MosaicTile[];
    reverse: boolean;
    speed: number;
    delay: number;
  }[] = [];
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

// With the browser's data saver on, the mosaic stays gradient-only: the
// covers are purely decorative and would be dozens of image downloads.
const saveData = useSaveData();

const { data: heroData } = useQuery<{ games: { nodes: HeroCoverNode[] } }>(GET_HERO_COVERS, {
  enabled: () => !saveData.value
});

const coverUrls = computed<string[]>(() => {
  if (saveData.value || !heroData.value) {
    return [];
  }
  return heroData.value.games.nodes.filter((g) => g.coverUrl).map((g) => g.coverUrl as string);
});

// Covers that have finished downloading. Tiles only switch to a cover once it
// is in here, so the CSS background is served from the cache and the low
// priority preload below is the only request for each image.
const loadedCoverUrls = ref<string[]>([]);
// Bumped each time the watcher below runs, so preloads started by an earlier
// run (before data saver was toggled, say) are ignored when they finish.
let coverPreloadRun = 0;

// Distribute cover images across tiles as they finish preloading
watch(
  coverUrls,
  (urls) => {
    const run = ++coverPreloadRun;
    loadedCoverUrls.value = [];
    if (urls.length === 0) {
      return;
    }
    const shuffled = [...urls];
    for (let i = shuffled.length - 1; i > 0; i--) {
      const j = Math.floor(Math.random() * (i + 1));
      [shuffled[i], shuffled[j]] = [shuffled[j], shuffled[i]];
    }
    const tilesByUrl = new Map<string, number[]>();
    for (let i = 0; i < TOTAL; i++) {
      const row = Math.floor(i / COLS_PER_ROW);
      const col = i % COLS_PER_ROW;
      // Keep ~25% as gradients for visual variety
      const keepGradient = (row * 3 + col * 7 + row * col) % 4 === 0;
      if (!keepGradient) {
        const url = shuffled[i % shuffled.length];
        tilesByUrl.set(url, [...(tilesByUrl.get(url) ?? []), i]);
      }
    }

    // Preload cover images before revealing mosaic. The mosaic is decorative,
    // so these downloads go at low priority and stay out of the way of the
    // page's data and the shelf covers below the hero.
    const uniqueUrls = [...new Set(shuffled)];
    let loaded = 0;
    const threshold = Math.floor(uniqueUrls.length * 0.75);

    for (const url of uniqueUrls) {
      const img = new Image();
      img.fetchPriority = "low";
      const onDone = (ok: boolean) => {
        if (run !== coverPreloadRun) {
          return;
        }
        if (ok) {
          loadedCoverUrls.value.push(url);
          for (const i of tilesByUrl.get(url) ?? []) {
            const tile = mosaicTiles.value[i];
            if (!tile.flipped) {
              tile.style = coverStyle(url);
            }
          }
        }
        loaded++;
        if (loaded >= threshold && !coversReady.value) {
          coversReady.value = true;
        }
      };
      img.addEventListener("load", () => onDone(true));
      img.addEventListener("error", () => onDone(false));
      img.src = url;
    }
  },
  { immediate: true }
);

// ── Flip animation system ──

let flipTimer: ReturnType<typeof setInterval> | null = null;
// The reveal fallback and the delayed flip start, cleared on unmount so a
// page that's gone can't start flipping.
const startTimers: ReturnType<typeof setTimeout>[] = [];

function flipTile() {
  const tiles = mosaicTiles.value;
  const idx = Math.floor(Math.random() * tiles.length);
  const tile = tiles[idx];
  if (tile.flipping) {
    return;
  }

  tile.flipping = true;
  tile.flipped = true;

  // Swap background at the midpoint (when card is edge-on at 90deg)
  setTimeout(() => {
    // Only flip to covers that already downloaded, so a flip never starts a
    // fresh, normal priority image request.
    const urls = loadedCoverUrls.value;
    if (urls.length > 0 && Math.random() > 0.2) {
      tile.style = coverStyle(urls[Math.floor(Math.random() * urls.length)]);
    } else {
      const newIdx = Math.floor(Math.random() * PALETTES.length);
      const angle = 110 + Math.floor(Math.random() * 70);
      tile.style = {
        background: `linear-gradient(${angle}deg, ${PALETTES[newIdx][0]}, ${PALETTES[newIdx][1]})`
      };
    }
  }, 400);

  setTimeout(() => {
    tile.flipping = false;
  }, 800);
}

function scheduleFlips() {
  const count = 3 + Math.floor(Math.random() * 3); // 3-5 flips per batch
  for (let i = 0; i < count; i++) {
    setTimeout(flipTile, i * 220 + Math.random() * 320);
  }
}

onMounted(() => {
  // No covers to wait for, so show the gradients right away.
  if (saveData.value) {
    coversReady.value = true;
  }

  // Fallback: show mosaic after 5s even if images haven't finished preloading
  startTimers.push(
    setTimeout(() => {
      coversReady.value = true;
    }, 5000)
  );
});

// Start flipping once covers are visible
watch(coversReady, (ready) => {
  if (ready && !flipTimer) {
    startTimers.push(
      setTimeout(() => {
        scheduleFlips();
        flipTimer = setInterval(scheduleFlips, 2000);
      }, 300)
    );
  }
});

onUnmounted(() => {
  for (const timer of startTimers) {
    clearTimeout(timer);
  }
  if (flipTimer) {
    clearInterval(flipTimer);
  }
  quickResizeObserver?.disconnect();
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

/* The width is set explicitly because browsers disagree on the shrink-to-fit
   width of this absolutely positioned box. Firefox sizes it to the space left
   in the scene (150%), while Chrome uses the rows' full max-content width
   (~4800px). That moves the transform origin far to the right in Chrome, so
   the rotated mosaic no longer covers the left side of the hero. */
.cover-mosaic {
  position: absolute;
  top: -45%;
  left: -50%;
  width: 150%;
  transform: rotateX(12deg) rotateZ(-23deg);
  transform-style: preserve-3d;
  opacity: 0;
  display: flex;
  flex-direction: column;
  gap: 10px;
  transition: opacity 0.8s ease-in;
}

.cover-mosaic.covers-loaded {
  opacity: 0.59;
}

/* ── Row-based scrolling ── */
/* Each row holds its tiles twice and scrolls by -50% of its own width, so the
   second copy lands exactly where the first started. That only holds if the
   row's width is two equal copies of tile + gap: the trailing padding is the
   gap after the last tile, without which -50% falls 5px short of one copy and
   the whole row jumps sideways every time the animation loops. The row must
   also be as wide as its tiles (max-content) rather than stretched to the
   mosaic's width, or -50% is half the mosaic instead of one copy. */
.mosaic-row {
  display: flex;
  width: max-content;
  gap: 10px;
  padding-right: 10px;
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
  animation: flipCard 0.8s ease-in-out;
}

@keyframes flipCard {
  0% {
    transform: rotateY(0deg) scale(1);
  }
  50% {
    transform: rotateY(90deg) scale(1.05);
  }
  100% {
    transform: rotateY(0deg) scale(1);
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
  background: linear-gradient(to top, #110b24 0%, transparent 100%);
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
  width: 100%;
  max-width: 840px;
  margin: 0 auto;
  padding: 5rem 1.5rem 4rem;
  text-align: center;
  color: #fff;
}

.home-heading {
  margin: 0;
  line-height: 0;
}

.home-logo {
  filter: drop-shadow(0 4px 20px rgba(0, 0, 0, 0.5)) drop-shadow(0 1px 4px rgba(0, 0, 0, 0.3));
}

.home-lede {
  margin-top: 1.25rem;
  font-size: 1.375rem;
  line-height: 1.4;
  color: #fff;
  text-wrap: balance;
}

/* Looks like a search field; it's a button because typing happens in the overlay. */
.home-search {
  display: flex;
  align-items: center;
  gap: 12px;
  width: 100%;
  max-width: 640px;
  height: 56px;
  margin: 2rem auto 0;
  padding: 0 12px 0 18px;
  border: 0;
  border-radius: var(--radius-lg);
  background: #fff;
  box-shadow: 0 8px 32px rgba(0, 0, 0, 0.35);
  color: var(--n-700);
  font: inherit;
  text-align: left;
  cursor: text;
}

.home-search:focus-visible {
  outline: 3px solid var(--p-300);
  outline-offset: 3px;
}

.home-search-text {
  flex: 1;
  min-width: 0;
  overflow: hidden;
  color: var(--n-500);
  font-size: 1.0625rem;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.home-search-kbd {
  padding: 2px 6px;
  border: 1px solid var(--n-200);
  border-radius: 5px;
  background: none;
  color: var(--n-500);
  font-family: inherit;
  font-size: 0.75rem;
}

/* Always one pill tall, loaded or not, so the page doesn't jump. */
.home-quick-slot {
  height: 36px;
  max-width: 640px;
  margin: 1.25rem auto 0;
}

/* Pills that don't fit wrap onto a second row, which is clipped away. */
.home-quick {
  display: flex;
  flex-wrap: wrap;
  justify-content: center;
  gap: 8px;
  height: 100%;
  overflow: hidden;
}

/* The cut-off pills, out of the tab order and the accessibility tree too. */
.home-quick-link.is-overflowing {
  visibility: hidden;
}

/* White rather than SkeletonBlock's text tint, which is dark in light mode
   and would vanish against the hero. */
.home-quick .home-quick-skeleton {
  --skeleton-fill: rgba(255, 255, 255, 0.12);
  --skeleton-shine: rgba(255, 255, 255, 0.1);

  height: 36px;
  border: 1px solid rgba(255, 255, 255, 0.16);
  border-radius: 999px;
}

.home-quick-link {
  display: inline-flex;
  flex-shrink: 0;
  align-items: center;
  height: 36px;
  padding: 0 14px;
  border: 1px solid rgba(255, 255, 255, 0.24);
  border-radius: 999px;
  background: rgba(255, 255, 255, 0.12);
  color: #fff;
  font-size: 0.875rem;
  white-space: nowrap;
  transition: background var(--transition-fast);
}

.home-quick-link:hover {
  background: rgba(255, 255, 255, 0.22);
  color: #fff;
}

.home-quick-link:focus-visible {
  outline: 2px solid #fff;
  outline-offset: 2px;
}

/* ── Below the hero ── */
.home-body {
  display: flex;
  flex-direction: column;
  gap: 3rem;
  padding-top: 3rem;
}

.home-banner {
  display: flex;
  flex-wrap: wrap;
  align-items: center;
  gap: 16px;
  padding: 18px 24px;
  border-radius: var(--radius-lg);
  background: var(--p-50);
  color: var(--color-text-primary);
}

.home-banner-icon {
  display: flex;
  flex-shrink: 0;
  align-items: center;
  justify-content: center;
  width: 40px;
  height: 40px;
  border-radius: 10px;
  background: var(--p-100);
  color: var(--p-600);
}

.home-banner-text {
  flex: 1;
  min-width: 240px;
  font-size: 0.9375rem;
  line-height: 1.45;
}

.home-banner-btn {
  display: inline-flex;
  align-items: center;
  min-height: 44px;
  padding: 0 22px;
  border-radius: var(--radius-button);
  background: var(--p-500);
  color: #fff;
  font-weight: 600;
  white-space: nowrap;
}

.home-banner-btn:hover {
  background: var(--p-600);
  color: #fff;
}

.home-banner-btn:focus-visible {
  outline: 2px solid var(--p-500);
  outline-offset: 2px;
}

.home-stats {
  margin-bottom: 1rem;
  color: var(--color-text-secondary);
  font-size: 0.8125rem;
  text-align: center;
}

@media (prefers-color-scheme: dark) {
  .home-banner {
    background: var(--p-800);
  }

  .home-banner-icon {
    background: var(--p-700);
    color: var(--p-200);
  }
}

/* ── Responsive ── */
@media (max-width: 900px) {
  .home-section.hero {
    min-height: 420px;
  }
}

@media (max-width: 600px) {
  .hero-content {
    padding: 3rem 1rem 2.5rem;
  }

  .home-lede {
    font-size: 1.125rem;
  }

  .home-search {
    height: 52px;
  }

  .home-search-kbd {
    display: none;
  }

  .home-banner {
    padding: 16px;
  }

  .home-banner-btn {
    width: 100%;
    justify-content: center;
  }
}
</style>
