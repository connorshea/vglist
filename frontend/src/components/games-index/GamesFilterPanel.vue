<template>
  <div
    ref="panelRef"
    class="filter-panel"
    :class="`is-${variant}`"
    role="dialog"
    tabindex="-1"
    :aria-modal="variant === 'sheet'"
    :aria-labelledby="variant === 'sheet' ? 'games-filter-panel-title' : undefined"
    :aria-label="variant === 'popover' ? 'More filters' : undefined"
    @keydown="onKeydown"
  >
    <div v-if="variant === 'sheet'" class="filter-panel-head">
      <h2 id="games-filter-panel-title" class="filter-panel-title">Filters</h2>
      <button type="button" class="filter-panel-close" aria-label="Close filters" @click="emit('close')">
        <X :size="16" aria-hidden="true" />
      </button>
    </div>

    <div class="filter-panel-body">
      <div v-if="variant === 'sheet'" class="filter-group">
        <label class="filter-heading" for="games-filter-platform">Platform</label>
        <FilterSearchSelect
          :model-value="modelValue.platform"
          :selected-name="names.platform"
          label="Platform"
          placeholder="Any platform"
          input-id="games-filter-platform"
          :query="SEARCH_PLATFORMS_FOR_FILTER"
          :result-nodes="(d) => (d as SearchPlatformsForFilterQuery).platformSearch?.nodes ?? []"
          @select="(o) => pick('platform', o)"
        />
      </div>

      <fieldset class="filter-group">
        <legend class="filter-heading">Genre</legend>
        <div class="pill-row">
          <button
            v-for="genre in genrePills"
            :key="genre.id"
            type="button"
            class="filter-pill"
            :class="{ on: modelValue.genre === genre.id }"
            :aria-pressed="modelValue.genre === genre.id"
            @click="pick('genre', modelValue.genre === genre.id ? null : genre)"
          >
            {{ genre.name }}
          </button>
          <button
            type="button"
            class="filter-pill"
            :aria-expanded="showGenreSearch"
            aria-controls="games-filter-genre-search"
            @click="showGenreSearch = !showGenreSearch"
          >
            {{ showGenreSearch ? "Fewer genres" : "All genres…" }}
          </button>
        </div>
        <div v-if="showGenreSearch" id="games-filter-genre-search" class="genre-search">
          <label class="is-sr-only" for="games-filter-genre">Search all genres</label>
          <FilterSearchSelect
            :model-value="modelValue.genre"
            :selected-name="names.genre"
            label="Genre"
            placeholder="Search genres"
            input-id="games-filter-genre"
            :query="SEARCH_GENRES_FOR_FILTER"
            :result-nodes="(d) => (d as SearchGenresForFilterQuery).genreSearch?.nodes ?? []"
            @select="(o) => pick('genre', o)"
          />
        </div>
      </fieldset>

      <fieldset class="filter-group">
        <legend class="filter-heading">Release year</legend>
        <div class="year-range">
          <div class="year-select">
            <label class="is-sr-only" for="games-filter-from">Released from</label>
            <select
              id="games-filter-from"
              :value="modelValue.fromYear"
              :class="{ 'is-placeholder': !modelValue.fromYear }"
              @change="setYear('fromYear', $event)"
            >
              <option value="">From</option>
              <option v-for="year in years" :key="year" :value="String(year)">{{ year }}</option>
            </select>
            <ChevronDown :size="14" class="year-chevron" aria-hidden="true" />
          </div>
          <span class="year-dash" aria-hidden="true">&ndash;</span>
          <div class="year-select">
            <label class="is-sr-only" for="games-filter-to">Released to</label>
            <select
              id="games-filter-to"
              :value="modelValue.toYear"
              :class="{ 'is-placeholder': !modelValue.toYear }"
              @change="setYear('toYear', $event)"
            >
              <option value="">To</option>
              <option v-for="year in years" :key="year" :value="String(year)">{{ year }}</option>
            </select>
            <ChevronDown :size="14" class="year-chevron" aria-hidden="true" />
          </div>
        </div>
      </fieldset>

      <div class="filter-group">
        <label class="filter-heading" for="games-filter-engine">Engine</label>
        <FilterSearchSelect
          :model-value="modelValue.engine"
          :selected-name="names.engine"
          label="Engine"
          placeholder="Any engine"
          input-id="games-filter-engine"
          :query="SEARCH_ENGINES_FOR_FILTER"
          :result-nodes="(d) => (d as SearchEnginesForFilterQuery).engineSearch?.nodes ?? []"
          @select="(o) => pick('engine', o)"
        />
      </div>

      <label v-if="signedIn" class="toggle-row">
        <input
          type="checkbox"
          role="switch"
          class="toggle-input"
          :checked="modelValue.hideLibrary"
          @change="update({ hideLibrary: ($event.target as HTMLInputElement).checked })"
        />
        <span class="toggle" aria-hidden="true"></span>
        Hide games in my library
      </label>
    </div>

    <div class="filter-panel-foot">
      <button type="button" class="clear-btn" @click="emit('update:modelValue', { ...EMPTY_FILTERS })">Clear</button>
      <button type="button" class="apply-btn" @click="emit('apply')">
        {{ count === null ? "Show games" : `Show ${countLabel(count, "game")}` }}
      </button>
    </div>
  </div>
</template>

<script setup lang="ts">
import { computed, onMounted, ref } from "vue";
import { ChevronDown, X } from "@lucide/vue";
import {
  SEARCH_ENGINES_FOR_FILTER,
  SEARCH_GENRES_FOR_FILTER,
  SEARCH_PLATFORMS_FOR_FILTER
} from "@/graphql/queries/games-index";
import type {
  SearchEnginesForFilterQuery,
  SearchGenresForFilterQuery,
  SearchPlatformsForFilterQuery
} from "@/types/graphql";
import FilterSearchSelect from "./FilterSearchSelect.vue";
import { EARLIEST_YEAR, EMPTY_FILTERS, countLabel, type GameFilters } from "./format";

interface NamedRecord {
  id: string;
  name: string;
}

const props = defineProps<{
  /** The filters being edited. They only take effect on `apply`. */
  modelValue: GameFilters;
  /** Names for the platform, genre and engine IDs in `modelValue`. */
  names: { platform: string | null; genre: string | null; engine: string | null };
  /** The most common genres, offered as pills. */
  genres: NamedRecord[];
  /** How many games the edited filters match, or null while unknown. */
  count: number | null;
  signedIn: boolean;
  /** A popover under its button on wide screens, a bottom sheet on phones. */
  variant: "popover" | "sheet";
}>();

const emit = defineEmits<{
  "update:modelValue": [value: GameFilters];
  /** A platform, genre or engine was picked, so its name is known. */
  named: [record: NamedRecord];
  apply: [];
  close: [];
}>();

const panelRef = ref<HTMLElement | null>(null);
const showGenreSearch = ref(false);

const years = computed(() => {
  const list: number[] = [];
  for (let y = new Date().getFullYear() + 1; y >= EARLIEST_YEAR; y--) list.push(y);
  return list;
});

// The most common genres, plus the picked genre if it isn't one of them.
const genrePills = computed(() => {
  const picked = props.modelValue.genre;
  if (picked && !props.genres.some((g) => g.id === picked) && props.names.genre) {
    return [...props.genres, { id: picked, name: props.names.genre }];
  }
  return props.genres;
});

function update(changes: Partial<GameFilters>) {
  emit("update:modelValue", { ...props.modelValue, ...changes });
}

function pick(key: "platform" | "genre" | "engine", record: NamedRecord | null) {
  if (record) emit("named", record);
  update({ [key]: record?.id ?? "" });
}

function setYear(key: "fromYear" | "toYear", event: Event) {
  const value = (event.target as HTMLSelectElement).value;
  const changes: Partial<GameFilters> = { [key]: value };
  // Keep the range the right way round.
  const { fromYear, toYear } = { ...props.modelValue, ...changes };
  if (value && fromYear && toYear && Number(fromYear) > Number(toYear)) {
    if (key === "fromYear") changes.toYear = value;
    else changes.fromYear = value;
  }
  update(changes);
}

// ── Focus management ──
const FOCUSABLE =
  'button:not([disabled]), input:not([disabled]), select:not([disabled]), [href], [tabindex]:not([tabindex="-1"])';

function focusables(): HTMLElement[] {
  return Array.from(panelRef.value?.querySelectorAll<HTMLElement>(FOCUSABLE) ?? []);
}

onMounted(() => {
  // Focus the dialog itself so its name is announced, without opening a
  // search field's results list by focusing into it.
  panelRef.value?.focus();
});

function onKeydown(e: KeyboardEvent) {
  if (e.key === "Escape") {
    e.preventDefault();
    emit("close");
    return;
  }
  if (e.key !== "Tab") return;
  const items = focusables();
  if (items.length === 0) return;
  const first = items[0];
  const last = items[items.length - 1];
  if (document.activeElement === panelRef.value) {
    e.preventDefault();
    (e.shiftKey ? last : first).focus();
  } else if (e.shiftKey && document.activeElement === first) {
    e.preventDefault();
    last.focus();
  } else if (!e.shiftKey && document.activeElement === last) {
    e.preventDefault();
    first.focus();
  }
}
</script>

<style scoped>
.filter-panel {
  display: flex;
  outline: none;
  flex-direction: column;
  background: var(--color-surface);
  color: var(--color-text-primary);
}

.filter-panel.is-popover {
  position: absolute;
  z-index: 30;
  top: calc(100% + 8px);
  right: 0;
  width: 360px;
  max-height: min(640px, calc(100vh - 140px));
  border: 1px solid var(--color-border);
  border-radius: var(--radius-lg);
  box-shadow:
    0 16px 48px rgba(0, 0, 0, 0.12),
    0 2px 8px rgba(0, 0, 0, 0.06);
}

.filter-panel.is-sheet {
  position: fixed;
  z-index: 50;
  left: 0;
  right: 0;
  bottom: 0;
  max-height: 85vh;
  border-radius: var(--radius-lg) var(--radius-lg) 0 0;
  box-shadow: 0 -4px 32px rgba(0, 0, 0, 0.12);
}

.filter-panel-head {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 16px 20px 0;
}

.filter-panel-title {
  font-size: 16px;
  font-weight: 600;
}

.filter-panel-close {
  display: flex;
  padding: 6px;
  border: none;
  border-radius: var(--radius-sm);
  background: none;
  color: var(--color-text-secondary);
  cursor: pointer;
}

.filter-panel-body {
  display: flex;
  flex-direction: column;
  gap: 18px;
  padding: 20px;
  overflow-y: auto;
}

.filter-group {
  min-width: 0;
  margin: 0;
  padding: 0;
  border: none;
}

.filter-heading {
  display: block;
  margin: 0 0 8px;
  padding: 0;
  font-size: 11px;
  font-weight: 600;
  letter-spacing: 0.08em;
  text-transform: uppercase;
  color: var(--color-text-tertiary);
}

.pill-row {
  display: flex;
  flex-wrap: wrap;
  gap: 8px;
}

.filter-pill {
  padding: 4.8px 12px;
  border: 1px solid var(--color-border);
  border-radius: var(--radius-pill);
  background: transparent;
  color: var(--color-text-secondary);
  font: inherit;
  font-size: 12px;
  cursor: pointer;
}

.filter-pill:hover {
  border-color: var(--color-text-tertiary);
  color: var(--color-text-primary);
}

.filter-pill.on {
  border-color: var(--p-100);
  background: var(--p-100);
  color: var(--p-700);
  font-weight: 500;
}

.genre-search {
  margin-top: 10px;
}

.year-range {
  display: flex;
  align-items: center;
  gap: 8px;
}

.year-select {
  position: relative;
  flex: 1;
}

.year-select select {
  width: 100%;
  height: 34px;
  padding: 0 28px 0 10px;
  border: 1px solid var(--color-border);
  border-radius: var(--radius-sm);
  background: var(--color-surface);
  color: var(--color-text-primary);
  font: inherit;
  font-size: 13px;
  appearance: none;
  cursor: pointer;
}

.year-select select.is-placeholder {
  color: var(--color-text-tertiary);
}

.year-select option {
  color: var(--color-text-primary);
}

.year-chevron {
  position: absolute;
  top: 50%;
  right: 10px;
  transform: translateY(-50%);
  color: var(--color-text-tertiary);
  pointer-events: none;
}

.year-dash {
  color: var(--color-text-tertiary);
}

.toggle-row {
  position: relative;
  display: flex;
  align-items: center;
  gap: 10px;
  font-size: 13px;
  color: var(--color-text-secondary);
  cursor: pointer;
}

.toggle-input {
  position: absolute;
  opacity: 0;
  pointer-events: none;
}

.toggle {
  position: relative;
  flex-shrink: 0;
  width: 36px;
  height: 20px;
  border-radius: 10px;
  background: var(--color-border);
  transition: background-color var(--transition-fast);
}

.toggle::after {
  content: "";
  position: absolute;
  top: 2px;
  left: 2px;
  width: 16px;
  height: 16px;
  border-radius: 50%;
  background: #fff;
  box-shadow: 0 1px 2px rgba(0, 0, 0, 0.2);
  transition: left var(--transition-fast);
}

.toggle-input:checked + .toggle {
  background: var(--p-500);
}

.toggle-input:checked + .toggle::after {
  left: 18px;
}

.filter-panel-foot {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 12px;
  padding: 14px 20px;
  border-top: 1px solid var(--color-border);
}

.clear-btn {
  padding: 0;
  border: none;
  background: none;
  color: var(--color-accent);
  font: inherit;
  font-size: 13px;
  font-weight: 500;
  cursor: pointer;
}

.apply-btn {
  padding: 7px 18px;
  border: 1.5px solid var(--vglist-theme);
  border-radius: var(--radius-pill);
  background: var(--vglist-theme);
  color: #fff;
  font: inherit;
  font-size: 13.6px;
  font-weight: 500;
  cursor: pointer;
}

.apply-btn:hover {
  background: var(--p-600);
  border-color: var(--p-600);
}

.filter-pill:focus-visible,
.filter-panel-close:focus-visible,
.clear-btn:focus-visible,
.apply-btn:focus-visible,
.year-select select:focus-visible {
  outline: 2px solid var(--color-accent);
  outline-offset: 2px;
}

.toggle-row:has(.toggle-input:focus-visible) .toggle {
  outline: 2px solid var(--color-accent);
  outline-offset: 2px;
}

@media (prefers-color-scheme: dark) {
  .filter-pill.on {
    border-color: transparent;
    background: color-mix(in srgb, var(--p-300) 22%, transparent);
    color: var(--p-100);
  }

  .filter-panel.is-popover {
    box-shadow: 0 16px 48px rgba(0, 0, 0, 0.45);
  }
}
</style>
