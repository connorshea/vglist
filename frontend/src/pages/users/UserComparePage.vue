<template>
  <div class="compare-page library-page" :class="{ 'is-phone': isPhone }">
    <div v-if="loading && !data" class="compare-message">
      <p>Loading…</p>
    </div>

    <div v-else-if="error" class="compare-message">
      <p class="compare-message-title">{{ error.message }}</p>
      <router-link :to="{ name: 'user', params: { slug: route.params.slug } }">Back to the profile</router-link>
    </div>

    <template v-if="comparison">
      <!-- ── Header ── -->
      <header class="compare-header">
        <div class="compare-identity">
          <span class="compare-duo" aria-hidden="true">
            <span class="compare-avatar is-a">
              <img v-if="userA.avatarUrl" :src="userA.avatarUrl" alt="" />
              <span v-else class="compare-avatar-initial">{{ initial(userA.username) }}</span>
            </span>
            <span class="compare-avatar is-b">
              <img v-if="userB.avatarUrl" :src="userB.avatarUrl" alt="" />
              <span v-else class="compare-avatar-initial">{{ initial(userB.username) }}</span>
            </span>
          </span>
          <div class="compare-identity-text">
            <h1 class="compare-title">
              <template v-if="isPhone && viewerIsA">You</template>
              <router-link v-else :to="{ name: 'user', params: { slug: userA.slug } }">{{
                userA.username
              }}</router-link>
              <span class="compare-amp"> &amp; </span>
              <router-link :to="{ name: 'user', params: { slug: userB.slug } }">{{ userB.username }}</router-link>
            </h1>
            <p class="compare-stats">{{ statsLine }}</p>
          </div>
        </div>
        <div class="compare-actions">
          <router-link
            :to="{ name: 'userCompare', params: { slug: userB.slug, otherSlug: userA.slug }, query: swappedQuery }"
            class="compare-button"
            :class="{ 'is-icon': isPhone }"
            :aria-label="isPhone ? 'Swap sides' : undefined"
          >
            <ArrowLeftRight :size="14" aria-hidden="true" />
            <template v-if="!isPhone">Swap sides</template>
          </router-link>
          <button
            type="button"
            class="compare-button"
            :class="{ 'is-icon': isPhone }"
            :aria-label="isPhone ? 'Compare with someone else' : undefined"
            @click="showPicker = true"
          >
            <UserSearch :size="14" aria-hidden="true" />
            <template v-if="!isPhone">Compare with someone else</template>
          </button>
        </div>
      </header>

      <!-- ── Overlap band ── -->
      <section class="compare-band" aria-label="Library overlap">
        <div class="compare-overlap" role="img" :aria-label="overlapLabel">
          <i v-if="shares.onlyA > 0" class="ov-a" :style="{ width: `${shares.onlyA}%` }"></i>
          <i v-if="shares.both > 0" class="ov-both" :style="{ width: `${shares.both}%` }"></i>
          <i v-if="shares.onlyB > 0" class="ov-b" :style="{ width: `${shares.onlyB}%` }"></i>
        </div>
        <div class="compare-band-stats">
          <div class="compare-band-stat">
            <span class="compare-swatch ov-a" aria-hidden="true"></span>
            <div>
              <b>{{ comparison.onlyACount.toLocaleString() }}</b>
              <span>{{ isPhone ? `Only ${nameA}` : `Only ${userA.username} has` }}</span>
            </div>
          </div>
          <div class="compare-band-stat">
            <span class="compare-swatch ov-both" aria-hidden="true"></span>
            <div>
              <b>{{ comparison.inCommonCount.toLocaleString() }}</b>
              <span v-if="isPhone">In common</span>
              <span v-else
                >In both libraries · {{ sharePercent(comparison.inCommonCount, countA) }} of
                {{ userA.username }}'s</span
              >
            </div>
          </div>
          <div class="compare-band-stat">
            <span class="compare-swatch ov-b" aria-hidden="true"></span>
            <div>
              <b>{{ comparison.onlyBCount.toLocaleString() }}</b>
              <span>{{ isPhone ? `Only ${userB.username}` : `Only ${userB.username} has` }}</span>
            </div>
          </div>
        </div>
      </section>

      <!-- ── Tabs ── -->
      <nav v-if="isPhone" class="compare-pills" aria-label="Comparison sections">
        <router-link
          v-for="tab in phoneTabs"
          :key="tab.key"
          :to="tabLink(tab.key)"
          class="compare-pill"
          :class="{ 'is-active': activeTab === tab.key }"
          :aria-current="activeTab === tab.key ? 'page' : undefined"
        >
          <span class="compare-pill-label">{{ tab.label }}</span>
          <span class="compare-pill-count">{{ tab.count.toLocaleString() }}</span>
        </router-link>
      </nav>
      <nav v-else class="compare-tabs" aria-label="Comparison sections">
        <router-link
          v-for="tab in tabs"
          :key="tab.key"
          :to="tabLink(tab.key)"
          :class="{ 'is-active': activeTab === tab.key }"
          :aria-current="activeTab === tab.key ? 'page' : undefined"
        >
          {{ tab.label }}
          <span v-if="tab.count !== null" class="compare-tab-count">{{ tab.count.toLocaleString() }}</span>
        </router-link>
      </nav>

      <!-- ── In common (Overview and the In common tab) ── -->
      <section v-if="activeTab === 'overview' || activeTab === 'common'" aria-labelledby="compare-common-heading">
        <div class="compare-toolbar">
          <h2 id="compare-common-heading" class="compare-h2" :class="{ 'is-sr-only': isPhone }">
            In common <span class="compare-h2-count">{{ comparison.inCommonCount.toLocaleString() }}</span>
          </h2>
          <span class="compare-grow"></span>
          <label class="compare-search">
            <span class="is-sr-only">Search shared games</span>
            <Search :size="14" aria-hidden="true" />
            <input v-model="commonSearch" type="search" placeholder="Search shared games…" />
          </label>
          <div class="compare-seg" role="group" aria-label="Which shared games to show">
            <button
              type="button"
              :class="{ 'is-active': bothRated }"
              :aria-pressed="bothRated"
              @click="bothRated = true"
            >
              Both rated
            </button>
            <button
              type="button"
              :class="{ 'is-active': !bothRated }"
              :aria-pressed="!bothRated"
              @click="bothRated = false"
            >
              All shared
            </button>
          </div>
          <label class="compare-select">
            <span class="is-sr-only">Sort by</span>
            <select :value="commonSort" @change="setCommonSort(($event.target as HTMLSelectElement).value)">
              <option v-for="sort in IN_COMMON_SORTS" :key="sort.key" :value="sort.key">
                {{ sort.label(userA.username, userB.username) }}
              </option>
            </select>
            <ChevronDown :size="14" aria-hidden="true" />
          </label>
        </div>

        <!-- Phone: a list with both scores side by side -->
        <template v-if="isPhone">
          <div class="compare-chead" aria-hidden="true">
            <span>{{ currentSortLabel }}</span>
            <span class="compare-pair">
              <span class="compare-mav is-a">{{ initial(userA.username) }}</span>
              <span class="compare-mav is-b">{{ initial(userB.username) }}</span>
            </span>
          </div>
          <ul class="compare-rows">
            <li v-for="row in commonRows" :key="row.game.id">
              <router-link
                :to="{ name: 'game', params: { id: row.game.id } }"
                class="compare-row"
                :aria-label="rowLabel(row)"
              >
                <span class="compare-row-cover">
                  <img v-if="row.game.coverUrl" :src="row.game.coverUrl" alt="" loading="lazy" />
                  <span v-else class="cover-placeholder" aria-hidden="true">{{ gameInitials(row.game.name) }}</span>
                </span>
                <span class="compare-row-text" aria-hidden="true">
                  <b>{{ row.game.name }}</b>
                  <span class="compare-row-meta">
                    <span class="status-dot" :class="statusClass(row.purchaseA.completionStatus)"></span>
                    {{ statusLabel(row.purchaseA.completionStatus) }} ·
                    <span class="status-dot" :class="statusClass(row.purchaseB.completionStatus)"></span>
                    {{ statusLabel(row.purchaseB.completionStatus) }}
                  </span>
                </span>
                <span class="compare-pair" aria-hidden="true">
                  <b :class="row.purchaseA.rating === null ? 'is-none' : 'is-a'">{{ row.purchaseA.rating ?? "–" }}</b>
                  <b :class="row.purchaseB.rating === null ? 'is-none' : 'is-b'">{{ row.purchaseB.rating ?? "–" }}</b>
                </span>
              </router-link>
            </li>
          </ul>
        </template>

        <!-- Desktop: a table with rating bars and a rating gap meter -->
        <div v-else class="compare-table-box">
          <table class="compare-table">
            <caption class="is-sr-only">
              Games in both libraries
            </caption>
            <thead>
              <tr>
                <th v-for="column in columns" :key="column.sort" scope="col" :aria-sort="ariaSort(column.sort)">
                  <button
                    type="button"
                    class="compare-th"
                    :class="{ 'is-sorted': commonSort === column.sort }"
                    @click="setCommonSort(column.sort)"
                  >
                    <span
                      v-if="column.user"
                      class="compare-mav is-small"
                      :class="`is-${column.user}`"
                      aria-hidden="true"
                    >
                      {{ initial(column.label) }}
                    </span>
                    {{ column.label }}
                    <ChevronDown v-if="commonSort === column.sort" :size="12" aria-hidden="true" />
                  </button>
                </th>
              </tr>
            </thead>
            <tbody>
              <tr v-for="row in commonRows" :key="row.game.id">
                <td>
                  <router-link :to="{ name: 'game', params: { id: row.game.id } }" class="compare-game">
                    <span class="compare-game-cover">
                      <img v-if="row.game.coverUrl" :src="row.game.coverUrl" alt="" loading="lazy" />
                      <span v-else class="cover-placeholder" aria-hidden="true">{{ gameInitials(row.game.name) }}</span>
                    </span>
                    <span class="compare-game-text">
                      <span class="compare-game-name">{{ row.game.name }}</span>
                      <span v-if="row.game.developers.nodes.length" class="compare-game-dev">
                        {{ row.game.developers.nodes[0].name }}
                      </span>
                    </span>
                  </router-link>
                </td>
                <td v-for="side in SIDES" :key="side">
                  <span class="compare-cell">
                    <span class="compare-rating">
                      <span class="compare-rating-num">
                        <template v-if="purchaseFor(row, side).rating !== null">{{
                          purchaseFor(row, side).rating
                        }}</template>
                        <template v-else>
                          <span aria-hidden="true">–</span><span class="is-sr-only">Not rated</span>
                        </template>
                      </span>
                      <span class="compare-bar" :class="`is-${side}`" aria-hidden="true">
                        <i :style="{ width: `${purchaseFor(row, side).rating ?? 0}%` }"></i>
                      </span>
                    </span>
                    <span class="compare-status">
                      <span
                        class="status-dot"
                        :class="statusClass(purchaseFor(row, side).completionStatus)"
                        aria-hidden="true"
                      ></span>
                      {{ statusLabel(purchaseFor(row, side).completionStatus) }}
                    </span>
                  </span>
                </td>
                <td>
                  <span class="compare-cell is-gap">
                    <span class="compare-gapm" aria-hidden="true">
                      <i
                        v-if="gapMeter(row.ratingDifference)"
                        :class="`is-${gapMeter(row.ratingDifference)?.side}`"
                        :style="gapStyle(row.ratingDifference)"
                      ></i>
                    </span>
                    <span class="compare-gapn" :class="gapClass(row.ratingDifference)" aria-hidden="true">
                      {{ gapText(row.ratingDifference) }}
                    </span>
                    <span class="is-sr-only">{{
                      gapDescription(row.ratingDifference, userA.username, userB.username)
                    }}</span>
                  </span>
                </td>
              </tr>
            </tbody>
          </table>
        </div>

        <p v-if="!commonLoading && commonRows.length === 0" class="compare-empty">{{ commonEmptyMessage }}</p>

        <div v-if="activeTab === 'overview' && !isPhone && commonTotal > 0" class="compare-footer">
          <span
            >Showing {{ commonRows.length }} of {{ commonTotal.toLocaleString() }}
            {{ bothRated ? "rated in common" : "in common" }}</span
          >
          <router-link :to="tabLink('common')"
            >See all {{ comparison.inCommonCount.toLocaleString() }} shared games</router-link
          >
        </div>
        <div v-else-if="commonHasNextPage" class="compare-more">
          <button type="button" class="compare-button" :disabled="commonLoading" @click="loadMoreCommon">
            {{ commonLoading ? "Loading…" : "Load more" }}
          </button>
        </div>
      </section>

      <!-- ── Only-in shelves (Overview) ── -->
      <div v-if="activeTab === 'overview' && !isPhone" class="compare-cols">
        <section
          v-for="shelf in shelves"
          :key="shelf.side"
          class="compare-shelf"
          :aria-labelledby="`compare-shelf-${shelf.side}`"
        >
          <div class="compare-shelf-header">
            <span class="compare-mav" :class="`is-${shelf.side}`" aria-hidden="true">{{
              initial(shelf.user.username)
            }}</span>
            <h3 :id="`compare-shelf-${shelf.side}`">Only in {{ possessive(shelf.user.username) }} library</h3>
            <span class="compare-h2-count">{{ shelf.count.toLocaleString() }}</span>
            <router-link v-if="shelf.count > 0" :to="tabLink(shelf.tab)" class="compare-shelf-more"
              >Show all</router-link
            >
          </div>
          <p class="compare-shelf-desc">{{ shelf.description }}</p>
          <div v-if="shelf.purchases.length" class="compare-grid is-shelf">
            <LibraryGameTile v-for="purchase in shelf.purchases" :key="purchase.id" :purchase="purchase" hide-hours />
          </div>
          <p v-else class="compare-empty is-inline">Nothing here.</p>
        </section>
      </div>

      <!-- ── Only A / Only B tabs ── -->
      <section v-if="activeTab === 'only-a' || activeTab === 'only-b'" aria-labelledby="compare-only-heading">
        <div class="compare-toolbar">
          <h2 id="compare-only-heading" class="compare-h2" :class="{ 'is-sr-only': isPhone }">
            Only in {{ possessive(onlyUser.username) }} library
            <span class="compare-h2-count">{{ onlyTotal.toLocaleString() }}</span>
          </h2>
          <span class="compare-grow"></span>
          <label class="compare-search">
            <span class="is-sr-only">Search these games</span>
            <Search :size="14" aria-hidden="true" />
            <input v-model="onlySearch" type="search" placeholder="Search games…" />
          </label>
          <label class="compare-select">
            <span class="is-sr-only">Sort by</span>
            <select :value="onlySort" @change="setOnlySort(($event.target as HTMLSelectElement).value)">
              <option v-for="sort in ONLY_SORTS" :key="sort.key" :value="sort.key">{{ sort.label }}</option>
            </select>
            <ChevronDown :size="14" aria-hidden="true" />
          </label>
        </div>
        <div v-if="onlyPurchases.length" class="compare-grid">
          <LibraryGameTile v-for="purchase in onlyPurchases" :key="purchase.id" :purchase="purchase" hide-hours />
        </div>
        <p v-else-if="!onlyLoading" class="compare-empty">
          {{ onlySearchTerm ? `No games match “${onlySearchTerm}”.` : "Nothing here." }}
        </p>
        <div v-if="onlyHasNextPage" class="compare-more">
          <button type="button" class="compare-button" :disabled="onlyLoading" @click="loadMoreOnly">
            {{ onlyLoading ? "Loading…" : "Load more" }}
          </button>
        </div>
      </section>
    </template>

    <CompareUserDialog
      v-if="comparison"
      v-model="showPicker"
      :username="userA.username"
      :exclude="[userA.slug, userB.slug]"
      @select="compareWith"
    />
  </div>
</template>

<script setup lang="ts">
import { computed, onBeforeUnmount, onMounted, ref, watch } from "vue";
import { useRoute, useRouter, type LocationQueryRaw } from "vue-router";
import { ArrowLeftRight, ChevronDown, Search, UserSearch } from "@lucide/vue";
import { useQuery } from "@/composables/useGraphQL";
import { useAuthStore } from "@/stores/auth";
import { GET_COMPARISON_IN_COMMON, GET_COMPARISON_ONLY, GET_LIBRARY_COMPARISON } from "@/graphql/queries/compare";
import type {
  GamePurchaseCompletionStatus,
  GamePurchaseSort,
  GetComparisonInCommonQuery,
  GetComparisonOnlyQuery,
  GetLibraryComparisonQuery,
  LibraryComparisonSort
} from "@/types/graphql";
import {
  IN_COMMON_SORTS,
  ONLY_SORTS,
  gapDescription,
  gapMeter,
  isCompareTab,
  isInCommonSort,
  isOnlySort,
  overlapShares,
  sharePercent,
  type CompareTab
} from "@/utils/compare";
import { gameInitials, libraryStatus } from "@/utils/library";
import CompareUserDialog from "@/components/compare/CompareUserDialog.vue";
import LibraryGameTile from "@/components/library/LibraryGameTile.vue";
import "@/assets/stylesheets/library.scss";

// How many rows of the In common table the Overview shows, and how many games
// each "Only in…" shelf shows.
const OVERVIEW_ROWS = 10;
const SHELF_SIZE = 6;
const PAGE_SIZE = 50;
const PHONE_QUERY = "(max-width: 768px)";
const SIDES = ["a", "b"] as const;

const route = useRoute("userCompare");
const router = useRouter();
const authStore = useAuthStore();

// ── Layout ──────────────────────────────────────────────────────────────────
const isPhone = ref(false);
let phoneMedia: MediaQueryList | null = null;

function updateIsPhone() {
  isPhone.value = phoneMedia?.matches ?? false;
}

onMounted(() => {
  if (typeof window.matchMedia !== "function") return;
  phoneMedia = window.matchMedia(PHONE_QUERY);
  updateIsPhone();
  phoneMedia.addEventListener("change", updateIsPhone);
});

onBeforeUnmount(() => phoneMedia?.removeEventListener("change", updateIsPhone));

// ── Summary ─────────────────────────────────────────────────────────────────
const slugs = computed(() => ({ userASlug: route.params.slug, userBSlug: route.params.otherSlug }));

const { data, loading, error } = useQuery<GetLibraryComparisonQuery>(GET_LIBRARY_COMPARISON, {
  variables: () => ({ ...slugs.value, shelfCount: SHELF_SIZE })
});

watch([data, loading], () => {
  if (!loading.value && data.value && !data.value.libraryComparison) {
    void router.replace({ name: "notFound" });
  }
});

const comparison = computed(() => data.value?.libraryComparison ?? null);
// Only read once `comparison` is non-null, which the template guards on.
const userA = computed(() => comparison.value?.userA ?? { id: "", username: "", slug: "", avatarUrl: null });
const userB = computed(() => comparison.value?.userB ?? { id: "", username: "", slug: "", avatarUrl: null });
const countA = computed(() => (comparison.value ? comparison.value.onlyACount + comparison.value.inCommonCount : 0));
const countB = computed(() => (comparison.value ? comparison.value.onlyBCount + comparison.value.inCommonCount : 0));

const viewerIsA = computed(() => authStore.isAuthenticated && authStore.user?.id === userA.value.id);
// On a phone, the viewer's side is "you" to save space, as in the mockup.
const nameA = computed(() => (isPhone.value && viewerIsA.value ? "you" : userA.value.username));

function initial(username: string): string {
  return username.charAt(0).toUpperCase();
}

function possessive(username: string): string {
  if (viewerIsA.value && username === userA.value.username) return "your";
  return `${username}'s`;
}

function plural(count: number, noun: string): string {
  return `${count.toLocaleString()} ${noun}${count === 1 ? "" : "s"}`;
}

// "Comparing game libraries · 412 and 1,104 games · avg rating gap of 7 across
// 121 games you've both rated"
const statsLine = computed(() => {
  const c = comparison.value;
  if (!c) return "";
  if (isPhone.value) {
    return c.averageRatingGap === null
      ? "Comparing libraries"
      : `Comparing libraries · avg gap ${Math.round(c.averageRatingGap)}`;
  }
  const parts = ["Comparing game libraries", `${countA.value.toLocaleString()} and ${plural(countB.value, "game")}`];
  if (c.averageRatingGap !== null) {
    const who = viewerIsA.value ? "you've" : "they've";
    parts.push(
      `avg rating gap of ${Math.round(c.averageRatingGap)} across ${plural(c.bothRatedCount, "game")} ${who} both rated`
    );
  }
  return parts.join(" · ");
});

const shares = computed(() =>
  comparison.value
    ? overlapShares(comparison.value.onlyACount, comparison.value.inCommonCount, comparison.value.onlyBCount)
    : { onlyA: 0, both: 0, onlyB: 0 }
);

const overlapLabel = computed(() => {
  const c = comparison.value;
  if (!c) return "";
  return `${plural(c.onlyACount, "game")} only ${userA.value.username} has, ${c.inCommonCount.toLocaleString()} in common, ${plural(c.onlyBCount, "game")} only ${userB.value.username} has`;
});

// ── Tabs ────────────────────────────────────────────────────────────────────
const requestedTab = computed<CompareTab>(() => (isCompareTab(route.query.tab) ? route.query.tab : "overview"));
// The phone layout has no Overview; its first tab is In common.
const activeTab = computed<CompareTab>(() =>
  isPhone.value && requestedTab.value === "overview" ? "common" : requestedTab.value
);

const tabs = computed(() => [
  { key: "overview" as const, label: "Overview", count: null },
  { key: "common" as const, label: "In common", count: comparison.value?.inCommonCount ?? 0 },
  { key: "only-a" as const, label: `Only ${userA.value.username}`, count: comparison.value?.onlyACount ?? 0 },
  { key: "only-b" as const, label: `Only ${userB.value.username}`, count: comparison.value?.onlyBCount ?? 0 }
]);

const phoneTabs = computed(() =>
  tabs.value
    .filter((tab) => tab.key !== "overview")
    .map((tab) => ({ ...tab, label: tab.key === "only-a" ? `Only ${nameA.value}` : tab.label, count: tab.count ?? 0 }))
);

function tabLink(tab: CompareTab) {
  return { name: "userCompare" as const, params: route.params, query: tab === "overview" ? {} : { tab } };
}

// Swapping sides keeps the tab, flipping "Only A" and "Only B" so it still
// shows the same games.
const swappedQuery = computed<LocationQueryRaw>(() => {
  const flip: Partial<Record<CompareTab, CompareTab>> = { "only-a": "only-b", "only-b": "only-a" };
  const tab = flip[requestedTab.value] ?? requestedTab.value;
  return tab === "overview" ? {} : { tab };
});

const showPicker = ref(false);

function compareWith(slug: string) {
  void router.push({ name: "userCompare", params: { slug: userA.value.slug, otherSlug: slug } });
}

// ── Statuses ────────────────────────────────────────────────────────────────
function statusClass(status: GamePurchaseCompletionStatus | null): string {
  return libraryStatus(status)?.className ?? "st-none";
}

function statusLabel(status: GamePurchaseCompletionStatus | null): string {
  return libraryStatus(status)?.label ?? "No status";
}

// ── In common ───────────────────────────────────────────────────────────────
type CommonRow = NonNullable<GetComparisonInCommonQuery["libraryComparison"]>["inCommon"]["nodes"][number];

const commonSort = ref<LibraryComparisonSort>("RATING_GAP");
const bothRated = ref(true);
const commonSearch = ref("");
const commonSearchTerm = useDebounced(commonSearch);

function setCommonSort(value: string) {
  if (isInCommonSort(value)) commonSort.value = value;
}

const currentSortLabel = computed(
  () =>
    IN_COMMON_SORTS.find((sort) => sort.key === commonSort.value)?.label(userA.value.username, userB.value.username) ??
    ""
);

const columns = computed(() => [
  { sort: "GAME_NAME" as const, label: "Game", user: null },
  { sort: "USER_A_RATING" as const, label: userA.value.username, user: "a" },
  { sort: "USER_B_RATING" as const, label: userB.value.username, user: "b" },
  { sort: "RATING_GAP" as const, label: "Rating gap", user: null }
]);

function ariaSort(sort: LibraryComparisonSort): "ascending" | "descending" | undefined {
  if (commonSort.value !== sort) return undefined;
  return sort === "GAME_NAME" ? "ascending" : "descending";
}

const commonVariables = computed(() => ({
  ...slugs.value,
  first: activeTab.value === "overview" ? OVERVIEW_ROWS : PAGE_SIZE,
  sortBy: commonSort.value,
  search: commonSearchTerm.value || null,
  bothRated: bothRated.value
}));

const {
  data: commonData,
  loading: commonLoading,
  fetchMore: fetchMoreCommon
} = useQuery<GetComparisonInCommonQuery>(GET_COMPARISON_IN_COMMON, {
  variables: () => commonVariables.value,
  enabled: () => comparison.value !== null && (activeTab.value === "overview" || activeTab.value === "common")
});

const commonConnection = computed(() => commonData.value?.libraryComparison?.inCommon ?? null);
const commonRows = computed<CommonRow[]>(() => commonConnection.value?.nodes ?? []);
const commonTotal = computed(() => commonConnection.value?.totalCount ?? 0);
const commonHasNextPage = computed(() => commonConnection.value?.pageInfo.hasNextPage ?? false);

const commonEmptyMessage = computed(() => {
  if (commonSearchTerm.value) return `No shared games match “${commonSearchTerm.value}”.`;
  if (bothRated.value && (comparison.value?.inCommonCount ?? 0) > 0)
    return "There are no shared games you've both rated yet.";
  return "These libraries have no games in common.";
});

async function loadMoreCommon() {
  const cursor = commonConnection.value?.pageInfo.endCursor;
  if (!commonHasNextPage.value || commonLoading.value || !cursor) return;

  await fetchMoreCommon({ ...commonVariables.value, after: cursor }, (prev, next) => {
    if (!prev.libraryComparison || !next.libraryComparison) return next;
    return {
      libraryComparison: {
        inCommon: {
          ...next.libraryComparison.inCommon,
          nodes: [...prev.libraryComparison.inCommon.nodes, ...next.libraryComparison.inCommon.nodes]
        }
      }
    };
  });
}

function purchaseFor(row: CommonRow, side: "a" | "b") {
  return side === "a" ? row.purchaseA : row.purchaseB;
}

function gapStyle(difference: number | null) {
  const meter = gapMeter(difference);
  if (!meter) return {};
  // The bar grows out from the centre line, so half the meter is a gap of 25.
  return meter.side === "a" ? { right: "50%", width: `${meter.width}%` } : { left: "50%", width: `${meter.width}%` };
}

function gapText(difference: number | null): string {
  if (difference === null) return "–";
  return difference === 0 ? "=" : String(Math.abs(difference));
}

function gapClass(difference: number | null): string {
  if (difference === null || difference === 0) return "is-even";
  return difference > 0 ? "is-a" : "is-b";
}

// The phone row's link reads as one sentence, since its parts are visual.
function rowLabel(row: CommonRow): string {
  const rating = (username: string, value: number | null) =>
    value === null ? `${username} hasn't rated it` : `${username} rated it ${value}`;
  return [
    row.game.name,
    rating(userA.value.username, row.purchaseA.rating),
    rating(userB.value.username, row.purchaseB.rating)
  ].join(", ");
}

// ── Only-in shelves ─────────────────────────────────────────────────────────
const shelves = computed(() => {
  const c = comparison.value;
  if (!c) return [];
  return [
    {
      side: "a" as const,
      tab: "only-a" as const,
      user: c.userA,
      count: c.onlyACount,
      purchases: c.onlyA.nodes,
      description: `${possessive(c.userA.username).replace(/^your$/, "Your")} highest rated games that ${c.userB.username} doesn't have`
    },
    {
      side: "b" as const,
      tab: "only-b" as const,
      user: c.userB,
      count: c.onlyBCount,
      purchases: c.onlyB.nodes,
      description: `${c.userB.username}'s highest rated games ${viewerIsA.value ? "you don't have yet" : `that ${c.userA.username} doesn't have`}`
    }
  ];
});

// ── Only A / Only B tabs ────────────────────────────────────────────────────
const onlySort = ref<GamePurchaseSort>("HIGHEST_RATING");
const onlySearch = ref("");
const onlySearchTerm = useDebounced(onlySearch);
const onlySideA = computed(() => activeTab.value === "only-a");
const onlyUser = computed(() => (onlySideA.value ? userA.value : userB.value));

function setOnlySort(value: string) {
  if (isOnlySort(value)) onlySort.value = value;
}

const onlyVariables = computed(() => ({
  ...slugs.value,
  sideA: onlySideA.value,
  first: PAGE_SIZE,
  sortBy: onlySort.value,
  search: onlySearchTerm.value || null
}));

const {
  data: onlyData,
  loading: onlyLoading,
  fetchMore: fetchMoreOnly
} = useQuery<GetComparisonOnlyQuery>(GET_COMPARISON_ONLY, {
  variables: () => onlyVariables.value,
  enabled: () => comparison.value !== null && (activeTab.value === "only-a" || activeTab.value === "only-b")
});

const onlyConnection = computed(() => {
  const c = onlyData.value?.libraryComparison;
  return (onlySideA.value ? c?.onlyA : c?.onlyB) ?? null;
});
const onlyPurchases = computed(() => onlyConnection.value?.nodes ?? []);
const onlyTotal = computed(() => onlyConnection.value?.totalCount ?? 0);
const onlyHasNextPage = computed(() => onlyConnection.value?.pageInfo.hasNextPage ?? false);

async function loadMoreOnly() {
  const cursor = onlyConnection.value?.pageInfo.endCursor;
  if (!onlyHasNextPage.value || onlyLoading.value || !cursor) return;

  const key = onlySideA.value ? "onlyA" : "onlyB";
  await fetchMoreOnly({ ...onlyVariables.value, after: cursor }, (prev, next) => {
    const before = prev.libraryComparison?.[key];
    const after = next.libraryComparison?.[key];
    if (!before || !after) return next;
    return { libraryComparison: { [key]: { ...after, nodes: [...before.nodes, ...after.nodes] } } };
  });
}

// Clear the searches when switching to another pair of users.
watch(slugs, () => {
  commonSearch.value = "";
  onlySearch.value = "";
});

// ── Helpers ─────────────────────────────────────────────────────────────────
// A copy of `source` that only updates once typing pauses, so a search isn't
// sent for every keystroke.
function useDebounced(source: typeof commonSearch) {
  const debounced = ref(source.value.trim());
  let timer: ReturnType<typeof setTimeout> | undefined;
  watch(source, (value) => {
    clearTimeout(timer);
    timer = setTimeout(() => {
      debounced.value = value.trim();
    }, 250);
  });
  onBeforeUnmount(() => clearTimeout(timer));
  return debounced;
}
</script>

<style scoped>
.compare-page {
  /* The two sides' colours, from the mockups: purple for the first user and
     amber for the second. The "ink" shades are for text, so they pass
     contrast on the page background. */
  --cmp-a: var(--p-500);
  --cmp-b: #f59e0b;
  --cmp-a-ink: var(--p-500);
  --cmp-b-ink: #b45309;
  padding-bottom: 64px;
}

@media (prefers-color-scheme: dark) {
  .compare-page {
    --cmp-a-ink: var(--p-300);
    --cmp-b-ink: #fbbf24;
  }
}

.compare-message {
  padding: 48px 0;
  color: var(--color-text-secondary);
  text-align: center;
}

.compare-message-title {
  margin-bottom: 8px;
  color: var(--color-text-primary);
  font-weight: 600;
}

/* ── Header ── */
.compare-header {
  display: flex;
  flex-wrap: wrap;
  gap: 12px 16px;
  align-items: center;
  justify-content: space-between;
}

.compare-identity {
  display: flex;
  gap: 16px;
  align-items: center;
  min-width: 0;
}

.compare-identity-text {
  min-width: 0;
}

.compare-duo {
  display: flex;
  flex-shrink: 0;
  align-items: center;
}

.compare-avatar {
  display: flex;
  flex-shrink: 0;
  align-items: center;
  justify-content: center;
  width: 48px;
  height: 48px;
  overflow: hidden;
  border-radius: 12px;
  background: linear-gradient(135deg, var(--p-400), var(--p-300));
  color: #fff;
  font-size: 1.2rem;
  font-weight: 600;
}

.compare-avatar.is-b {
  margin-left: -14px;
  background: linear-gradient(135deg, #c2410c, #d97706);
  box-shadow: 0 0 0 3px var(--bulma-scheme-main);
}

.compare-avatar-initial {
  text-box: trim-both cap alphabetic;
}

.compare-avatar img {
  width: 100%;
  height: 100%;
  object-fit: cover;
}

.compare-title {
  margin: 0;
  color: var(--color-text-primary);
  font-size: 1.375rem;
  font-weight: 700;
  line-height: 1.2;
  overflow-wrap: anywhere;
}

.compare-title a {
  color: inherit;
}

.compare-title a:hover {
  color: var(--color-accent);
}

.compare-amp {
  color: var(--color-text-tertiary);
  font-weight: 400;
}

.compare-stats {
  margin: 2px 0 0;
  color: var(--color-text-secondary);
  font-size: 0.8rem;
}

.compare-actions {
  display: flex;
  gap: 8px;
  align-items: center;
}

.compare-button {
  display: inline-flex;
  gap: 6px;
  align-items: center;
  justify-content: center;
  height: 36px;
  padding: 0 16px;
  border: 1.5px solid var(--color-border);
  border-radius: var(--radius-pill);
  background: transparent;
  color: var(--color-text-primary);
  font: inherit;
  font-size: 0.85rem;
  font-weight: 500;
  cursor: pointer;
}

.compare-button:hover {
  border-color: var(--color-accent);
  color: var(--color-accent);
}

.compare-button.is-icon {
  width: 40px;
  height: 40px;
  padding: 0;
}

.compare-button:disabled {
  opacity: 0.6;
  cursor: default;
}

/* ── Overlap band ── */
.compare-band {
  margin-top: 24px;
  padding: 20px;
  border: 1px solid var(--color-border);
  border-radius: var(--radius-md);
  background: var(--color-surface);
}

.compare-overlap {
  display: flex;
  gap: 2px;
  height: 14px;
  overflow: hidden;
  border-radius: 7px;
  background: var(--color-bg-subtle);
}

.compare-overlap i {
  display: block;
  height: 100%;
}

.ov-a {
  background: var(--cmp-a);
}

.ov-b {
  background: var(--cmp-b);
}

/* Stripes rather than a third colour, so "both" reads as a mix of the two. */
.ov-both {
  background: repeating-linear-gradient(135deg, var(--cmp-a) 0 6px, var(--cmp-b) 6px 12px);
}

.compare-band-stats {
  display: grid;
  grid-template-columns: repeat(3, minmax(0, 1fr));
  gap: 12px;
  margin-top: 16px;
}

.compare-band-stat {
  display: flex;
  gap: 10px;
  align-items: flex-start;
  min-width: 0;
}

.compare-swatch {
  flex-shrink: 0;
  width: 12px;
  height: 12px;
  margin-top: 7px;
  border-radius: 3px;
}

.compare-band-stat b {
  display: block;
  color: var(--color-text-primary);
  font-size: 1.625rem;
  font-weight: 700;
  line-height: 1.1;
  letter-spacing: -0.02em;
}

.compare-band-stat span {
  color: var(--color-text-secondary);
  font-size: 0.75rem;
}

/* ── Tabs ── */
.compare-tabs {
  display: flex;
  margin-top: 24px;
  overflow-x: auto;
  border-bottom: 1px solid var(--color-border);
  scrollbar-width: none;
}

.compare-tabs a {
  display: flex;
  flex-shrink: 0;
  gap: 6px;
  align-items: center;
  margin-bottom: -1px;
  padding: 10px 16px;
  border-bottom: 2px solid transparent;
  color: var(--color-text-secondary);
  font-size: 0.875rem;
}

.compare-tabs a:hover {
  color: var(--color-text-primary);
}

.compare-tabs a.is-active {
  border-bottom-color: var(--color-accent);
  color: var(--color-accent);
  font-weight: 500;
}

.compare-tab-count {
  color: var(--color-text-tertiary);
  font-size: 0.7rem;
}

.compare-pills {
  display: flex;
  gap: 6px;
  margin: 0 -1.5rem;
  padding: 12px 1.5rem;
  overflow-x: auto;
  scrollbar-width: none;
}

.compare-pill {
  display: inline-flex;
  flex-shrink: 0;
  gap: 6px;
  align-items: center;
  min-height: 36px;
  padding: 0 14px;
  border: 1px solid var(--color-border);
  border-radius: 999px;
  color: var(--color-text-secondary);
  font-size: 0.8rem;
  font-weight: 500;
}

.compare-pill.is-active {
  border-color: var(--vglist-theme);
  background: var(--vglist-theme);
  color: #fff;
}

/* Trimmed to cap height and baseline so the letters, not the line box, are
   centred in the pill. Otherwise the font's descender space leaves more room
   below the text than above it. */
.compare-pill-label,
.compare-pill-count {
  text-box: trim-both cap alphabetic;
}

.compare-pill-count {
  opacity: 0.75;
  font-size: 0.7rem;
}

/* ── Toolbar ── */
.compare-toolbar {
  display: flex;
  flex-wrap: wrap;
  gap: 8px;
  align-items: center;
  margin: 20px 0 16px;
}

.compare-h2 {
  margin: 0;
  color: var(--color-text-primary);
  font-size: 1rem;
  font-weight: 600;
}

.compare-h2-count {
  color: var(--color-text-tertiary);
  font-size: 0.8rem;
  font-weight: 400;
}

.compare-grow {
  flex: 1;
}

.compare-search {
  display: flex;
  gap: 6px;
  align-items: center;
  width: 220px;
  height: 30px;
  padding: 0 8px;
  border: 1px solid var(--color-border);
  border-radius: 4px;
  background: var(--color-surface);
  color: var(--color-text-secondary);
}

.compare-search:focus-within {
  border-color: var(--color-accent);
}

.compare-search input {
  flex: 1;
  min-width: 0;
  border: 0;
  outline: 0;
  background: none;
  color: var(--color-text-primary);
  font: inherit;
  font-size: 0.75rem;
}

.compare-seg {
  display: inline-flex;
  overflow: hidden;
  border: 1px solid var(--color-border);
  border-radius: 4px;
}

.compare-seg button {
  height: 28px;
  padding: 0 10px;
  border: 0;
  background: var(--color-surface);
  color: var(--color-text-secondary);
  font: inherit;
  font-size: 0.75rem;
  cursor: pointer;
}

.compare-seg button + button {
  border-left: 1px solid var(--color-border);
}

.compare-seg button.is-active {
  background: var(--p-500);
  color: #fff;
}

.compare-select {
  position: relative;
  display: inline-flex;
  align-items: center;
  color: var(--color-text-secondary);
}

.compare-select select {
  height: 30px;
  padding: 0 26px 0 8px;
  border: 1px solid var(--color-border);
  border-radius: 4px;
  background: var(--color-surface);
  color: var(--color-text-primary);
  font: inherit;
  font-size: 0.75rem;
  cursor: pointer;
  appearance: none;
}

.compare-select svg {
  position: absolute;
  right: 8px;
  pointer-events: none;
}

/* ── Table ── */
.compare-table-box {
  overflow-x: auto;
  border: 1px solid var(--color-border);
  border-radius: var(--radius-md);
  background: var(--color-surface);
}

.compare-table {
  width: 100%;
  min-width: 820px;
  border-collapse: collapse;
  font-size: 0.8125rem;
}

.compare-table th {
  padding: 0;
  border-bottom: 1px solid var(--color-border);
  background: var(--color-bg-subtle);
  text-align: left;
}

.compare-table th:first-child {
  width: 40%;
}

.compare-table th:last-child {
  width: 150px;
}

.compare-th {
  display: flex;
  gap: 4px;
  align-items: center;
  width: 100%;
  padding: 10px 12px;
  border: 0;
  background: none;
  color: var(--color-text-tertiary);
  font: inherit;
  font-size: 0.6875rem;
  font-weight: 600;
  letter-spacing: 0.06em;
  text-transform: uppercase;
  white-space: nowrap;
  cursor: pointer;
}

.compare-th:hover,
.compare-th.is-sorted {
  color: var(--color-accent);
}

.compare-table td {
  padding: 8px 12px;
  border-bottom: 1px solid var(--color-border);
  vertical-align: middle;
}

.compare-table tbody tr:last-child td {
  border-bottom: 0;
}

.compare-game {
  display: flex;
  gap: 10px;
  align-items: center;
  min-width: 0;
}

.compare-game-cover {
  display: block;
  flex-shrink: 0;
  width: 30px;
  aspect-ratio: 3 / 4;
  overflow: hidden;
  border-radius: 4px;
  background: var(--color-bg-subtle);
  font-size: 0.55rem;
}

.compare-game-cover img {
  display: block;
  width: 100%;
  height: 100%;
  object-fit: cover;
}

.compare-game-text {
  min-width: 0;
}

.compare-game-name {
  display: block;
  color: var(--color-text-primary);
  font-weight: 500;
}

.compare-game:hover .compare-game-name {
  color: var(--color-accent);
}

.compare-game-dev {
  display: block;
  color: var(--color-text-secondary);
  font-size: 0.6875rem;
}

.compare-cell {
  display: flex;
  gap: 12px;
  align-items: center;
}

.compare-rating {
  display: inline-flex;
  gap: 8px;
  align-items: center;
  font-variant-numeric: tabular-nums;
}

.compare-rating-num {
  width: 22px;
  color: var(--color-text-primary);
  font-weight: 600;
  text-align: right;
}

.compare-bar {
  display: block;
  width: 56px;
  height: 5px;
  overflow: hidden;
  border-radius: 3px;
  background: var(--color-border);
}

.compare-bar i {
  display: block;
  height: 100%;
}

.compare-bar.is-a i {
  background: var(--cmp-a);
}

.compare-bar.is-b i {
  background: var(--cmp-b);
}

.compare-status {
  display: inline-flex;
  gap: 6px;
  align-items: center;
  color: var(--color-text-secondary);
  font-size: 0.75rem;
  white-space: nowrap;
}

.compare-status .status-dot {
  width: 7px;
  height: 7px;
}

.compare-gapm {
  position: relative;
  flex-shrink: 0;
  width: 64px;
  height: 6px;
  border-radius: 3px;
  background: var(--color-bg-subtle);
}

/* The centre line the bar grows out from. */
.compare-gapm::before {
  position: absolute;
  top: -3px;
  bottom: -3px;
  left: 50%;
  width: 1px;
  background: var(--color-text-tertiary);
  content: "";
}

.compare-gapm i {
  position: absolute;
  top: 0;
  bottom: 0;
  border-radius: 3px;
}

.compare-gapm i.is-a {
  background: var(--cmp-a);
}

.compare-gapm i.is-b {
  background: var(--cmp-b);
}

.compare-gapn {
  width: 24px;
  font-weight: 700;
  font-variant-numeric: tabular-nums;
  text-align: right;
}

.compare-gapn.is-a {
  color: var(--cmp-a-ink);
}

.compare-gapn.is-b {
  color: var(--cmp-b-ink);
}

.compare-gapn.is-even {
  color: var(--color-text-tertiary);
  font-weight: 500;
}

/* The little user badges in the column headers and shelves. */
/* Block containers trimmed to cap height and baseline, so the letter itself,
   not its line box (which has room for descenders), sits in the middle. */
.compare-mav {
  display: inline-block;
  flex-shrink: 0;
  align-content: center;
  text-align: center;
  text-box: trim-both cap alphabetic;
  width: 20px;
  height: 20px;
  border-radius: 6px;
  color: #fff;
  font-size: 0.6875rem;
  font-weight: 600;
  letter-spacing: 0;
  text-transform: none;
}

.compare-mav.is-small {
  width: 16px;
  height: 16px;
  border-radius: 4px;
  font-size: 0.625rem;
}

.compare-mav.is-a {
  background: var(--p-500);
}

.compare-mav.is-b {
  background: #c2410c;
}

.compare-footer {
  display: flex;
  flex-wrap: wrap;
  gap: 8px;
  justify-content: space-between;
  margin-top: 12px;
  color: var(--color-text-secondary);
  font-size: 0.75rem;
}

.compare-footer a,
.compare-shelf-more {
  color: var(--color-accent);
  font-weight: 500;
}

.compare-more {
  display: flex;
  justify-content: center;
  margin-top: 20px;
}

.compare-empty {
  padding: 32px 0;
  color: var(--color-text-secondary);
  font-size: 0.875rem;
  text-align: center;
}

.compare-empty.is-inline {
  padding: 8px 0;
  text-align: left;
}

/* ── Shelves ── */
.compare-cols {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(320px, 1fr));
  gap: 32px;
  margin-top: 40px;
}

.compare-shelf-header {
  display: flex;
  gap: 8px;
  align-items: center;
  margin-bottom: 12px;
}

.compare-shelf-header h3 {
  margin: 0;
  color: var(--color-text-primary);
  font-size: 0.95rem;
  font-weight: 600;
}

.compare-shelf-more {
  margin-left: auto;
  font-size: 0.75rem;
}

.compare-shelf-desc {
  margin: -4px 0 12px;
  color: var(--color-text-secondary);
  font-size: 0.75rem;
}

.compare-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(130px, 1fr));
  gap: 14px;
}

.compare-grid.is-shelf {
  grid-template-columns: repeat(3, minmax(0, 1fr));
}

/* ── Phone ── */
.compare-chead {
  display: flex;
  align-items: center;
  margin: 0 -1.5rem;
  padding: 8px 1.5rem;
  border-top: 1px solid var(--color-border);
  border-bottom: 1px solid var(--color-border);
  background: var(--color-bg-subtle);
  color: var(--color-text-tertiary);
  font-size: 0.6875rem;
  font-weight: 600;
  letter-spacing: 0.06em;
  text-transform: uppercase;
}

.compare-rows {
  margin: 0 -1.5rem;
  padding: 0;
  list-style: none;
}

.compare-row {
  display: flex;
  gap: 12px;
  align-items: center;
  padding: 10px 1.5rem;
  border-bottom: 1px solid var(--color-border);
  color: var(--color-text-primary);
}

.compare-row-cover {
  display: block;
  flex-shrink: 0;
  width: 40px;
  aspect-ratio: 3 / 4;
  overflow: hidden;
  border-radius: 5px;
  background: var(--color-bg-subtle);
  font-size: 0.6rem;
}

.compare-row-cover img {
  display: block;
  width: 100%;
  height: 100%;
  object-fit: cover;
}

.compare-row-text {
  flex: 1;
  min-width: 0;
}

.compare-row-text b {
  display: block;
  overflow: hidden;
  font-size: 0.875rem;
  font-weight: 600;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.compare-row-meta {
  display: flex;
  gap: 6px;
  align-items: center;
  color: var(--color-text-secondary);
  font-size: 0.75rem;
}

.compare-row-meta .status-dot {
  width: 7px;
  height: 7px;
}

.compare-pair {
  display: grid;
  flex-shrink: 0;
  grid-template-columns: 32px 32px;
  gap: 6px;
  margin-left: auto;
  text-align: center;
}

.compare-pair .compare-mav {
  margin: 0 auto;
}

.compare-pair b {
  font-size: 0.95rem;
  font-weight: 700;
}

.compare-pair b.is-a {
  color: var(--cmp-a-ink);
}

.compare-pair b.is-b {
  color: var(--cmp-b-ink);
}

.compare-pair b.is-none {
  color: var(--color-text-tertiary);
  font-weight: 500;
}

.is-phone .compare-avatar {
  width: 36px;
  height: 36px;
  border-radius: 10px;
  font-size: 0.95rem;
}

.is-phone .compare-identity {
  flex: 1;
  gap: 12px;
}

.is-phone .compare-header {
  flex-wrap: nowrap;
}

.is-phone .compare-title {
  font-size: 1.125rem;
}

.is-phone .compare-band {
  margin-top: 12px;
  padding: 14px;
}

.is-phone .compare-band-stats {
  gap: 8px;
  margin-top: 12px;
}

.is-phone .compare-band-stat {
  gap: 6px;
}

.is-phone .compare-swatch {
  width: 8px;
  height: 8px;
  margin-top: 6px;
}

.is-phone .compare-band-stat b {
  font-size: 1.125rem;
}

.is-phone .compare-band-stat span {
  font-size: 0.6875rem;
}

.is-phone .compare-toolbar {
  margin: 0 0 12px;
}

.is-phone .compare-grow {
  display: none;
}

.is-phone .compare-seg {
  flex: 1;
}

.is-phone .compare-seg button {
  flex: 1;
}

.is-phone .compare-search {
  flex: 1 1 100%;
  width: auto;
  height: 36px;
}

.is-phone .compare-seg button,
.is-phone .compare-select select {
  height: 36px;
}

.is-phone .compare-grid {
  grid-template-columns: repeat(3, minmax(0, 1fr));
  gap: 10px;
}

/* ── Focus ── */
.compare-title a:focus-visible,
.compare-button:focus-visible,
.compare-tabs a:focus-visible,
.compare-pill:focus-visible,
.compare-seg button:focus-visible,
.compare-select select:focus-visible,
.compare-th:focus-visible,
.compare-game:focus-visible,
.compare-row:focus-visible,
.compare-footer a:focus-visible,
.compare-shelf-more:focus-visible {
  outline: 2px solid var(--color-accent);
  outline-offset: 2px;
}

.compare-th:focus-visible,
.compare-row:focus-visible,
.compare-tabs a:focus-visible {
  outline-offset: -2px;
}
</style>
