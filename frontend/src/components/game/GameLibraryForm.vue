<template>
  <div class="form-card" :class="isSheet ? 'is-sheet' : 'is-drawer'" :aria-busy="!entryLoaded">
    <!-- Disabled until an existing entry has loaded, so nothing saves over it half-filled -->
    <fieldset class="form-fields" :disabled="!entryLoaded">
      <!-- Status: one tap picks it, a second tap clears it -->
      <div class="form-group" role="group" aria-labelledby="form-status-label">
        <div id="form-status-label" class="form-label">Status</div>
        <div class="form-tiles">
          <button
            v-for="opt in statusOptions"
            :key="opt.value"
            type="button"
            class="form-tile"
            :aria-pressed="formStatus === opt.value"
            @click="pickStatus(opt.value)"
          >
            <span class="form-tile-dot" :style="{ background: opt.color }" aria-hidden="true"></span>
            {{ opt.label }}
          </button>
        </div>
        <p v-if="dateHint" class="form-hint" role="status">
          <Info :size="16" aria-hidden="true" />
          <span>{{ dateHint.message }}</span>
          <button type="button" class="form-hint-undo" @click="undoDateHint">Undo</button>
        </p>
      </div>

      <div class="form-group">
        <label class="form-label" for="form-rating">Rating <small>out of 100</small></label>
        <div class="form-rating-row">
          <input
            id="form-rating"
            v-model.number="formRating"
            type="number"
            min="0"
            max="100"
            inputmode="numeric"
            class="form-input form-rating-input"
            placeholder="–"
            @input="clampRating"
          />
          <input
            :value="formRating ?? 0"
            type="range"
            min="0"
            max="100"
            class="form-rating-range"
            aria-label="Rating slider"
            @input="formRating = Number(($event.target as HTMLInputElement).value)"
          />
        </div>
      </div>

      <!-- Progress: hours, replays and dates -->
      <section class="form-section">
        <h3 class="form-section-heading">
          <button
            type="button"
            class="form-section-toggle"
            :aria-expanded="isOpen('progress')"
            aria-controls="form-section-progress"
            @click="toggleSection('progress')"
          >
            <ChevronDown v-if="isOpen('progress')" :size="18" aria-hidden="true" />
            <ChevronRight v-else :size="18" aria-hidden="true" />
            Progress
            <span v-if="!isOpen('progress')" class="form-section-summary">{{ progressSummary }}</span>
          </button>
        </h3>
        <div v-show="isOpen('progress')" id="form-section-progress" class="form-section-body">
          <div class="form-grid2">
            <div>
              <label class="form-label" for="form-hours-played">Hours played</label>
              <input
                id="form-hours-played"
                v-model.number="formHoursPlayed"
                type="number"
                min="0"
                step="0.1"
                inputmode="decimal"
                class="form-input"
                placeholder="0"
              />
            </div>
            <div>
              <label class="form-label" for="form-replay-count">Times replayed</label>
              <input
                id="form-replay-count"
                v-model.number="formReplayCount"
                type="number"
                min="0"
                step="1"
                inputmode="numeric"
                class="form-input"
                placeholder="0"
                @change="normalizeReplayCount"
              />
            </div>
            <div>
              <div class="form-label-row">
                <label class="form-label" for="form-start-date">Started</label>
                <button type="button" class="form-date-today" @click="setDate('start', today)">Today</button>
              </div>
              <input
                id="form-start-date"
                :value="formStartDate"
                type="date"
                class="form-input"
                :max="today"
                @input="setDate('start', ($event.target as HTMLInputElement).value)"
              />
            </div>
            <div>
              <div class="form-label-row">
                <label class="form-label" for="form-completion-date">Finished</label>
                <button type="button" class="form-date-today" @click="setDate('completion', today)">Today</button>
              </div>
              <input
                id="form-completion-date"
                :value="formCompletionDate"
                type="date"
                class="form-input"
                :max="today"
                @input="setDate('completion', ($event.target as HTMLInputElement).value)"
              />
            </div>
          </div>
          <p v-if="dateValidationError" class="form-date-error">
            {{ dateValidationError }}
          </p>
        </div>
      </section>

      <!-- Platforms and stores -->
      <section class="form-section">
        <h3 class="form-section-heading">
          <button
            type="button"
            class="form-section-toggle"
            :aria-expanded="isOpen('owned')"
            aria-controls="form-section-owned"
            @click="toggleSection('owned')"
          >
            <ChevronDown v-if="isOpen('owned')" :size="18" aria-hidden="true" />
            <ChevronRight v-else :size="18" aria-hidden="true" />
            Platforms &amp; store
            <span v-if="!isOpen('owned')" class="form-section-summary">{{ ownedSummary }}</span>
          </button>
        </h3>
        <div v-show="isOpen('owned')" id="form-section-owned" class="form-section-body">
          <div class="form-group-inner" role="group" aria-labelledby="form-platforms-label">
            <div id="form-platforms-label" class="form-label">Platforms played</div>
            <div class="form-pills">
              <button
                v-for="plat in gamePlatforms"
                :key="plat.id"
                type="button"
                class="form-pill"
                :aria-pressed="formPlatformIds.has(plat.id)"
                @click="toggleFormPlatform(plat.id)"
              >
                {{ plat.name }}
              </button>
              <span v-if="gamePlatforms.length === 0" class="form-empty-hint">No platforms listed for this game.</span>
            </div>
          </div>
          <div class="form-group-inner" role="group" aria-labelledby="form-stores-label">
            <div id="form-stores-label" class="form-label">Store</div>
            <div class="form-pills">
              <button
                v-for="store in visibleStores"
                :key="store.id"
                type="button"
                class="form-pill"
                :aria-pressed="formStoreIds.has(store.id)"
                @click="toggleFormStore(store.id)"
              >
                {{ store.name }}
              </button>
              <button
                v-if="hiddenStoreCount > 0"
                type="button"
                class="form-pill form-pill-more"
                @click="showAllStores = true"
              >
                + {{ hiddenStoreCount }} more
              </button>
              <span v-if="storesLoading" class="form-empty-hint">Loading stores…</span>
            </div>
          </div>
        </div>
      </section>

      <!-- Review -->
      <section class="form-section form-section-last">
        <h3 class="form-section-heading">
          <button
            type="button"
            class="form-section-toggle"
            :aria-expanded="isOpen('review')"
            aria-controls="form-section-review"
            @click="toggleSection('review')"
          >
            <ChevronDown v-if="isOpen('review')" :size="18" aria-hidden="true" />
            <ChevronRight v-else :size="18" aria-hidden="true" />
            Review
            <span v-if="!isOpen('review')" class="form-section-summary">{{ reviewSummary }}</span>
          </button>
        </h3>
        <div v-show="isOpen('review')" id="form-section-review" class="form-section-body">
          <label class="form-label" for="form-comments">Review / notes <small>shows on the game page</small></label>
          <textarea
            id="form-comments"
            v-model="formComments"
            class="form-input form-textarea"
            placeholder="What did you think?"
            maxlength="2000"
          ></textarea>
          <div class="form-count">{{ formComments.length }} / 2000</div>
        </div>
      </section>
    </fieldset>

    <button
      v-if="isEditing && isSheet"
      type="button"
      class="form-btn-remove form-btn-remove-wide"
      :disabled="removingFromLibrary"
      @click="$emit('requestRemove')"
    >
      <Trash2 :size="18" :stroke-width="1.8" aria-hidden="true" />
      {{ removingFromLibrary ? "Removing…" : "Remove from library" }}
    </button>

    <div class="form-actions">
      <button
        v-if="isEditing && !isSheet"
        type="button"
        class="form-btn-remove"
        :disabled="removingFromLibrary"
        @click="$emit('requestRemove')"
      >
        {{ removingFromLibrary ? "Removing…" : "Remove" }}
      </button>
      <div class="form-actions-right">
        <button type="button" class="form-btn-cancel" @click="$emit('cancel')">Cancel</button>
        <button
          type="button"
          class="form-btn-save"
          :disabled="saving || !entryLoaded || !!dateValidationError"
          @click="submit"
        >
          {{ saving ? "Saving…" : entryLoaded ? saveLabel : "Loading…" }}
        </button>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { computed, onMounted, ref, watch } from "vue";
import { gqlClient } from "@/graphql/client";
import { GET_GAME_PURCHASE } from "@/graphql/queries/games";
import { ADD_GAME_TO_LIBRARY, UPDATE_GAME_IN_LIBRARY } from "@/graphql/mutations/games";
import type { GetGamePurchaseQuery, GamePurchaseCompletionStatus } from "@/types/graphql";
import { REVIEW_DRAFT_KEY_PREFIX } from "@/stores/auth";
import { extractGqlError } from "@/utils/graphql-errors";
import { ChevronDown, ChevronRight, Info, Trash2 } from "@lucide/vue";

const props = withDefaults(
  defineProps<{
    gameId: string;
    gameName: string;
    gamePurchaseId: string | null;
    gamePlatforms: { id: string; name: string }[];
    allStores: { id: string; name: string }[];
    storesLoading: boolean;
    removingFromLibrary: boolean;
    /** "drawer" fills the side drawer on wide screens; "sheet" fills the phone bottom sheet. */
    variant?: "drawer" | "sheet";
  }>(),
  { variant: "drawer" }
);

const emit = defineEmits<{
  cancel: [];
  saved: [message: string];
  requestRemove: [];
  error: [message: string];
}>();

// Dot colours match the library page's status dots (library.scss).
const statusOptions: { value: GamePurchaseCompletionStatus; label: string; color: string }[] = [
  { value: "UNPLAYED", label: "Unplayed", color: "#a855f7" },
  { value: "IN_PROGRESS", label: "Playing", color: "#3b82f6" },
  { value: "PAUSED", label: "Paused", color: "#f59e0b" },
  { value: "DROPPED", label: "Dropped", color: "#ef4444" },
  { value: "COMPLETED", label: "Completed", color: "#22c55e" },
  { value: "FULLY_COMPLETED", label: "100%", color: "#16a34a" },
  { value: "NOT_APPLICABLE", label: "N/A", color: "#6b7280" }
];

const isSheet = computed(() => props.variant === "sheet");

const saveLabel = computed(() => {
  return isEditing.value ? "Save changes" : "Add to library";
});

// The full store list is several rows of chips, so the form shows the first
// few plus any you've picked, and the rest behind "+ N more".
const COLLAPSED_STORE_COUNT = 3;
const showAllStores = ref(false);

const visibleStores = computed(() => {
  if (showAllStores.value) return props.allStores;
  return props.allStores.filter((store, i) => i < COLLAPSED_STORE_COUNT || formStoreIds.value.has(store.id));
});

const hiddenStoreCount = computed(() => props.allStores.length - visibleStores.value.length);

const formStatus = ref<GamePurchaseCompletionStatus | null>(null);
const formRating = ref<number | null>(null);
const formStartDate = ref("");
const formCompletionDate = ref("");
// The local calendar date as YYYY-MM-DD. toISOString() would give the UTC date,
// which is already tomorrow on an evening in the Americas.
function localDate(date: Date): string {
  const month = String(date.getMonth() + 1).padStart(2, "0");
  const day = String(date.getDate()).padStart(2, "0");
  return `${date.getFullYear()}-${month}-${day}`;
}
const today = computed(() => localDate(new Date()));
const formPlatformIds = ref(new Set<string>());
const formStoreIds = ref(new Set<string>());
const formHoursPlayed = ref<number | null>(null);
const formReplayCount = ref<number | null>(null);
const formComments = ref("");
const isEditing = ref(false);
const saving = ref(false);
// False while an existing entry is loading, and stays false if it fails to
// load. Saving a half-filled form would wipe the entry: the API reads missing
// platforms and stores as "none".
const entryLoaded = ref(true);

// ── localStorage draft persistence ──
let suppressDraftSync = false;

function reviewDraftKey(): string {
  return `${REVIEW_DRAFT_KEY_PREFIX}${props.gameId}`;
}

function loadReviewDraft(): void {
  if (formComments.value !== "") return;
  const saved = localStorage.getItem(reviewDraftKey());
  if (saved) {
    formComments.value = saved;
  }
}

function clearReviewDraft(): void {
  localStorage.removeItem(reviewDraftKey());
}

watch(formComments, (value) => {
  if (suppressDraftSync) return;
  if (value.trim() === "") {
    clearReviewDraft();
  } else {
    localStorage.setItem(reviewDraftKey(), value);
  }
});

// ── Form logic ──
function resetForm() {
  formStatus.value = null;
  formRating.value = null;
  formHoursPlayed.value = null;
  formReplayCount.value = null;
  formStartDate.value = "";
  formCompletionDate.value = "";
  formPlatformIds.value = new Set();
  formStoreIds.value = new Set();
  formComments.value = "";
  isEditing.value = false;
  dateHint.value = null;
}

function openAsAdd() {
  suppressDraftSync = true;
  resetForm();
  suppressDraftSync = false;
  loadReviewDraft();
  // An unsent review draft is the first thing you'd want to see again.
  if (formComments.value !== "") openSections.value = new Set([...openSections.value, "review"]);
}

async function openAsEdit() {
  const purchaseId = props.gamePurchaseId;
  if (!purchaseId) return;

  suppressDraftSync = true;
  resetForm();
  isEditing.value = true;
  entryLoaded.value = false;

  try {
    const result = await gqlClient.request<GetGamePurchaseQuery>(GET_GAME_PURCHASE, {
      id: purchaseId
    });
    const gp = result.gamePurchase;
    if (!gp) {
      suppressDraftSync = false;
      return;
    }

    formStatus.value = (gp.completionStatus as GamePurchaseCompletionStatus) ?? null;
    formRating.value = gp.rating ?? null;
    formHoursPlayed.value = gp.hoursPlayed ?? null;
    formReplayCount.value = gp.replayCount;
    formStartDate.value = gp.startDate ?? "";
    formCompletionDate.value = gp.completionDate ?? "";
    formComments.value = gp.comments ?? "";
    suppressDraftSync = false;
    loadReviewDraft();
    formPlatformIds.value = new Set(gp.platforms.nodes.map((p) => p.id));
    formStoreIds.value = new Set(gp.stores.nodes.map((s) => s.id));
    entryLoaded.value = true;
  } catch {
    suppressDraftSync = false;
    emit("error", "Failed to load game purchase details.");
  }
}

function toggleFormPlatform(id: string) {
  const next = new Set(formPlatformIds.value);
  if (next.has(id)) {
    next.delete(id);
  } else {
    next.add(id);
  }
  formPlatformIds.value = next;
}

function toggleFormStore(id: string) {
  const next = new Set(formStoreIds.value);
  if (next.has(id)) {
    next.delete(id);
  } else {
    next.add(id);
  }
  formStoreIds.value = next;
}

function clampRating() {
  if (formRating.value == null) return;
  if (formRating.value > 100) formRating.value = 100;
  if (formRating.value < 0) formRating.value = 0;
}

// Replays are whole numbers; the API rejects negatives.
function normalizeReplayCount() {
  if (typeof formReplayCount.value !== "number" || Number.isNaN(formReplayCount.value)) {
    formReplayCount.value = null;
    return;
  }
  formReplayCount.value = Math.max(0, Math.floor(formReplayCount.value));
}

// ── Status with date defaults ──
// Picking Playing fills an empty Started date with today, and Completed or 100%
// fills an empty Finished date. A hint says so and offers Undo.
type DateField = "start" | "completion";
const dateHint = ref<{ field: DateField; message: string } | null>(null);

function setDate(field: DateField, value: string) {
  if (field === "start") {
    formStartDate.value = value;
  } else {
    formCompletionDate.value = value;
  }
  if (dateHint.value?.field === field) dateHint.value = null;
}

function undoDateHint() {
  const hint = dateHint.value;
  if (!hint) return;
  setDate(hint.field, "");
}

function pickStatus(value: GamePurchaseCompletionStatus) {
  // Changing your mind takes back the date the previous pick filled in.
  undoDateHint();
  const next = formStatus.value === value ? null : value;
  formStatus.value = next;

  if (next === "IN_PROGRESS" && !formStartDate.value) {
    formStartDate.value = today.value;
    dateHint.value = { field: "start", message: "Started set to today" };
  } else if ((next === "COMPLETED" || next === "FULLY_COMPLETED") && !formCompletionDate.value) {
    formCompletionDate.value = today.value;
    dateHint.value = { field: "completion", message: "Finished set to today" };
  }
}

// ── Collapsible sections ──
type SectionKey = "progress" | "owned" | "review";
// The drawer has room to start with Progress open; the phone sheet starts
// with every section closed so Save is on screen straight away.
const openSections = ref(new Set<SectionKey>(props.variant === "drawer" ? ["progress"] : []));

function isOpen(key: SectionKey): boolean {
  // A date problem has to be visible to be fixed.
  if (key === "progress" && dateValidationError.value) return true;
  return openSections.value.has(key);
}

function toggleSection(key: SectionKey) {
  const next = new Set(openSections.value);
  if (isOpen(key)) {
    next.delete(key);
  } else {
    next.add(key);
  }
  openSections.value = next;
}

function formatDate(iso: string): string {
  const [year, month, day] = iso.split("-").map(Number);
  return new Date(year, month - 1, day).toLocaleDateString("en-US", {
    month: "short",
    day: "numeric",
    year: "numeric"
  });
}

const progressSummary = computed(() => {
  const parts: string[] = [];
  if (typeof formHoursPlayed.value === "number" && formHoursPlayed.value > 0) parts.push(`${formHoursPlayed.value} h`);
  if (typeof formReplayCount.value === "number" && formReplayCount.value > 0) {
    parts.push(`replayed ${formReplayCount.value}×`);
  }
  if (formStartDate.value) parts.push(`started ${formatDate(formStartDate.value)}`);
  if (formCompletionDate.value) parts.push(`finished ${formatDate(formCompletionDate.value)}`);
  if (parts.length === 0) return "Not set";
  const text = parts.join(" · ");
  return text.charAt(0).toUpperCase() + text.slice(1);
});

const ownedSummary = computed(() => {
  const names = [
    ...props.gamePlatforms.filter((p) => formPlatformIds.value.has(p.id)).map((p) => p.name),
    ...props.allStores.filter((s) => formStoreIds.value.has(s.id)).map((s) => s.name)
  ];
  return names.length > 0 ? names.join(" · ") : "Not set";
});

const reviewSummary = computed(() => formComments.value.trim() || "Optional");

const dateValidationError = computed(() => {
  const todayStr = today.value;
  if (formStartDate.value && formStartDate.value > todayStr) {
    return "Start date cannot be in the future.";
  }
  if (formCompletionDate.value && formCompletionDate.value > todayStr) {
    return "Completion date cannot be in the future.";
  }
  if (formStartDate.value && formCompletionDate.value && formStartDate.value > formCompletionDate.value) {
    return "Start date must be on or before the completion date.";
  }
  return "";
});

// v-model.number leaves "" behind when a number field is emptied.
function numberOrNull(value: number | string | null): number | null {
  return typeof value === "number" && Number.isFinite(value) ? value : null;
}

function buildFormVariables(): Record<string, unknown> {
  const variables: Record<string, unknown> = {};
  // When editing, a cleared field goes out as null so the server clears it
  // too; leaving it out would keep the old value.
  const put = (key: string, value: unknown) => {
    if (value !== null) {
      variables[key] = value;
    } else if (isEditing.value) {
      variables[key] = null;
    }
  };

  const rating = numberOrNull(formRating.value);
  const hours = numberOrNull(formHoursPlayed.value);
  const replays = numberOrNull(formReplayCount.value);

  put("completionStatus", formStatus.value);
  put("rating", rating !== null && rating >= 0 ? Math.round(Math.min(100, rating)) : null);
  put("hoursPlayed", hours !== null && hours >= 0 ? hours : null);
  // An emptied field means no replays, so an edit can clear an existing count.
  if (replays !== null && replays >= 0) {
    variables.replayCount = Math.floor(replays);
  } else if (isEditing.value) {
    variables.replayCount = 0;
  }
  put("startDate", formStartDate.value || null);
  put("completionDate", formCompletionDate.value || null);
  if (formPlatformIds.value.size > 0) {
    variables.platforms = [...formPlatformIds.value];
  }
  if (formStoreIds.value.size > 0) {
    variables.stores = [...formStoreIds.value];
  }
  put("comments", formComments.value.trim() || null);

  return variables;
}

async function submit() {
  if (!entryLoaded.value) return;
  if (dateValidationError.value) {
    emit("error", dateValidationError.value);
    return;
  }

  saving.value = true;
  const variables = buildFormVariables();

  try {
    if (isEditing.value) {
      variables.gamePurchaseId = props.gamePurchaseId;
      await gqlClient.request(UPDATE_GAME_IN_LIBRARY, variables);
      clearReviewDraft();
      emit("saved", `${props.gameName} has been updated in your library.`);
    } else {
      variables.gameId = props.gameId;
      await gqlClient.request(ADD_GAME_TO_LIBRARY, variables);
      clearReviewDraft();
      emit("saved", `${props.gameName} has been added to your library.`);
    }
  } catch (err) {
    const action = isEditing.value ? "update" : "add";
    emit("error", `Failed to ${action} game in library: ${extractGqlError(err)}`);
  } finally {
    saving.value = false;
  }
}

// Load the entry (or a fresh form) as soon as the drawer or sheet mounts it.
onMounted(() => {
  if (props.gamePurchaseId) {
    openAsEdit();
  } else {
    openAsAdd();
  }
});

defineExpose({ openAsAdd, openAsEdit });
</script>

<style scoped>
/* The form fills the drawer (wide screens) or the bottom sheet (phones). The
   drawer or sheet scrolls; the actions row sticks to the bottom of it. */
.form-card {
  --form-pad: 24px;
  color: var(--color-text-primary);
  text-align: left;
}

.form-fields {
  min-width: 0;
  margin: 0;
  padding: 0;
  border: none;
}

.form-group {
  padding: 18px var(--form-pad) 0;
}

.form-label {
  display: flex;
  align-items: baseline;
  justify-content: space-between;
  gap: 8px;
  margin: 0 0 8px;
  font-size: 13px;
  font-weight: 600;
  color: var(--color-text-primary);
}

.form-label small {
  font-size: 12.5px;
  font-weight: 400;
  color: var(--n-500);
}

/* ── Status tiles ── */
.form-tiles {
  display: grid;
  grid-template-columns: repeat(4, minmax(0, 1fr));
  gap: 8px;
}

.form-tile {
  display: flex;
  flex-direction: column;
  align-items: flex-start;
  justify-content: space-between;
  gap: 8px;
  min-height: 58px;
  padding: 10px 10px 9px;
  border: 1px solid var(--color-border);
  border-radius: 10px;
  background: transparent;
  color: var(--color-text-primary);
  font: inherit;
  font-size: 13.5px;
  font-weight: 600;
  text-align: left;
  cursor: pointer;
}

.form-tile:hover {
  border-color: var(--n-400);
}

.form-tile[aria-pressed="true"] {
  border-color: var(--p-500);
  background: var(--p-50);
  box-shadow: inset 0 0 0 1px var(--p-500);
  color: var(--p-700);
}

.form-tile-dot {
  width: 8px;
  height: 8px;
  flex-shrink: 0;
  border-radius: 50%;
}

.form-hint {
  display: flex;
  align-items: center;
  gap: 8px;
  margin: 10px 0 0;
  padding: 6px 6px 6px 10px;
  border-radius: var(--radius-md);
  background: var(--color-bg-subtle);
  font-size: 13px;
  color: var(--n-500);
}

.form-hint svg {
  flex-shrink: 0;
  color: var(--p-500);
}

.form-hint-undo {
  margin-left: auto;
  padding: 4px 8px;
  border: none;
  border-radius: var(--radius-sm);
  background: none;
  color: var(--p-500);
  font: inherit;
  font-weight: 600;
  cursor: pointer;
}

/* ── Inputs ── */
.form-input {
  width: 100%;
  height: 36px;
  box-sizing: border-box;
  padding: 0 10px;
  border: 1px solid var(--color-border);
  border-radius: var(--radius-md);
  background: var(--color-surface);
  color: var(--color-text-primary);
  font: inherit;
  font-size: 14px;
  outline: none;
}

.form-input:focus {
  border-color: var(--p-500);
}

.form-input::placeholder {
  color: var(--color-placeholder);
}

.form-rating-row {
  display: flex;
  align-items: center;
  gap: 12px;
}

.form-rating-input {
  width: 64px;
  flex-shrink: 0;
  text-align: center;
  font-weight: 600;
}

.form-rating-range {
  flex: 1;
  min-width: 0;
  margin: 0;
  accent-color: var(--p-500);
}

.form-grid2 {
  display: grid;
  grid-template-columns: repeat(2, minmax(0, 1fr));
  gap: 14px 12px;
}

.form-label-row {
  display: flex;
  align-items: baseline;
  justify-content: space-between;
}

.form-date-today {
  margin-bottom: 8px;
  padding: 0;
  border: none;
  background: none;
  color: var(--p-500);
  font: inherit;
  font-size: 12.5px;
  font-weight: 600;
  cursor: pointer;
}

.form-date-today:hover {
  color: var(--p-600);
  text-decoration: underline;
}

.form-date-error {
  margin: 10px 0 0;
  color: var(--date-error, #cc0000);
  font-size: 13px;
}

.form-textarea {
  height: auto;
  min-height: 120px;
  padding: 10px 12px;
  line-height: 1.45;
  resize: vertical;
}

.form-count {
  margin-top: 6px;
  text-align: right;
  font-size: 12px;
  color: var(--n-500);
}

/* ── Collapsible sections ── */
.form-section {
  margin: 18px var(--form-pad) 0;
  border-top: 1px solid var(--color-border);
}

.form-section + .form-section {
  margin-top: 0;
}

.form-section-last {
  border-bottom: 1px solid var(--color-border);
}

.form-section-heading {
  margin: 0;
  font-size: inherit;
}

.form-section-toggle {
  display: flex;
  align-items: center;
  gap: 10px;
  width: 100%;
  min-height: 52px;
  padding: 0;
  border: none;
  background: transparent;
  color: var(--color-text-primary);
  font: inherit;
  font-size: 15px;
  font-weight: 600;
  text-align: left;
  cursor: pointer;
}

.form-section-toggle svg {
  flex-shrink: 0;
  color: var(--n-500);
}

.form-section-summary {
  min-width: 0;
  margin-left: auto;
  overflow: hidden;
  font-size: 13.5px;
  font-weight: 400;
  color: var(--n-500);
  text-overflow: ellipsis;
  white-space: nowrap;
}

.form-section-body {
  padding: 0 0 18px;
}

.form-group-inner + .form-group-inner {
  margin-top: 16px;
}

/* ── Chips for platforms and stores ── */
.form-pills {
  display: flex;
  flex-wrap: wrap;
  gap: 6px;
}

.form-pill {
  display: inline-flex;
  align-items: center;
  height: 32px;
  padding: 0 12px;
  border: 1px solid var(--color-border);
  border-radius: var(--radius-pill);
  background: transparent;
  color: var(--color-text-primary);
  font: inherit;
  font-size: 13px;
  cursor: pointer;
}

.form-pill:hover {
  border-color: var(--n-400);
}

.form-pill[aria-pressed="true"] {
  border-color: var(--p-500);
  background: var(--p-100);
  color: var(--p-700);
  font-weight: 600;
}

.form-pill-more {
  border-style: dashed;
  color: var(--n-500);
}

.form-empty-hint {
  font-size: 13px;
  font-style: italic;
  color: var(--n-500);
}

/* ── Actions ── */
.form-actions {
  position: sticky;
  bottom: 0;
  z-index: 1;
  display: flex;
  align-items: center;
  gap: 10px;
  margin-top: 24px;
  padding: 14px var(--form-pad) calc(14px + env(safe-area-inset-bottom));
  border-top: 1px solid var(--color-border);
  background: var(--color-surface);
}

.form-actions-right {
  display: flex;
  gap: 10px;
  margin-left: auto;
}

.form-btn-remove,
.form-btn-cancel,
.form-btn-save {
  height: 40px;
  padding: 0 16px;
  border-radius: var(--radius-button);
  font: inherit;
  font-size: 14px;
  font-weight: 600;
  cursor: pointer;
}

.form-btn-remove {
  border: none;
  background: none;
  padding: 0 8px;
  margin-left: -8px;
  color: #b3261e;
}

.form-btn-remove:hover {
  background: #fdf0ef;
}

.form-btn-cancel {
  border: 1px solid var(--color-border);
  background: transparent;
  color: var(--color-text-primary);
}

.form-btn-cancel:hover {
  background: var(--color-bg-subtle);
}

.form-btn-save {
  border: 1px solid var(--p-500);
  background: var(--p-500);
  color: #fff;
}

.form-btn-save:hover {
  background: var(--p-600);
}

.form-btn-remove:disabled,
.form-btn-save:disabled {
  opacity: 0.6;
  cursor: not-allowed;
}

.form-tile:focus-visible,
.form-pill:focus-visible,
.form-hint-undo:focus-visible,
.form-section-toggle:focus-visible,
.form-date-today:focus-visible,
.form-btn-remove:focus-visible,
.form-btn-cancel:focus-visible,
.form-btn-save:focus-visible {
  outline: 2px solid var(--p-500);
  outline-offset: 2px;
}

/* ── Sheet (phones): 44px targets, and 16px text so iOS doesn't zoom ── */
.is-sheet {
  --form-pad: 20px;
}

.is-sheet .form-group {
  padding-top: 16px;
}

.is-sheet .form-label {
  margin-bottom: 10px;
  font-size: 14px;
}

.is-sheet .form-tiles {
  gap: 6px;
}

.is-sheet .form-tile {
  min-height: 64px;
  padding: 10px 8px;
  font-size: 13px;
}

.is-sheet .form-hint {
  font-size: 14px;
}

.is-sheet .form-hint-undo {
  min-height: 44px;
  margin: -6px 0 -6px auto;
}

.is-sheet .form-input {
  height: 44px;
  border-radius: 10px;
  font-size: 16px;
}

.is-sheet .form-textarea {
  height: auto;
  padding: 12px;
  resize: none;
}

.is-sheet .form-rating-row {
  gap: 14px;
}

.is-sheet .form-rating-input {
  width: 72px;
}

.is-sheet .form-rating-range {
  height: 44px;
}

.is-sheet .form-grid2 {
  grid-template-columns: minmax(0, 1fr);
  gap: 12px;
}

.is-sheet .form-label-row {
  align-items: center;
  margin-bottom: 6px;
}

.is-sheet .form-label-row .form-label {
  margin: 0;
}

.is-sheet .form-date-today {
  min-height: 44px;
  margin: -10px -8px -10px 0;
  padding: 0 8px;
  font-size: 14px;
}

.is-sheet .form-section-toggle {
  min-height: 56px;
  font-size: 16px;
}

.is-sheet .form-pills {
  gap: 8px;
}

.is-sheet .form-pill {
  min-height: 44px;
  padding: 0 16px;
  font-size: 15px;
}

.form-btn-remove-wide {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 8px;
  width: calc(100% - 40px);
  height: auto;
  min-height: 48px;
  margin: 24px 20px 4px;
  border: 1px solid #e8c4c0;
  border-radius: 12px;
  font-size: 15px;
}

.is-sheet .form-actions {
  margin-top: 20px;
  padding-top: 12px;
}

.is-sheet .form-actions-right {
  flex: 1;
  margin-left: 0;
}

.is-sheet .form-btn-cancel,
.is-sheet .form-btn-save {
  height: auto;
  min-height: 48px;
  border-radius: 12px;
  font-size: 16px;
}

.is-sheet .form-btn-cancel {
  flex: 0 0 112px;
}

.is-sheet .form-btn-save {
  flex: 1;
}

/* ── Dark mode ── */
@media (prefers-color-scheme: dark) {
  .form-label small,
  .form-hint,
  .form-count,
  .form-section-toggle svg,
  .form-section-summary,
  .form-pill-more,
  .form-empty-hint {
    color: var(--s-100);
  }

  .form-tile:hover,
  .form-pill:hover {
    border-color: var(--s-200);
  }

  .form-tile[aria-pressed="true"] {
    border-color: var(--p-300);
    background: rgba(206, 203, 246, 0.14);
    box-shadow: inset 0 0 0 1px var(--p-300);
    color: var(--p-200);
  }

  .form-pill[aria-pressed="true"] {
    border-color: var(--p-300);
    background: rgba(206, 203, 246, 0.14);
    color: var(--p-200);
  }

  .form-hint {
    background: var(--s-600);
  }

  .form-hint svg,
  .form-hint-undo {
    color: var(--p-300);
  }

  .form-input {
    background: var(--s-600);
    color: var(--s-50);
  }

  .form-input:focus {
    border-color: var(--p-300);
  }

  .form-rating-range {
    accent-color: var(--p-300);
  }

  .form-date-today {
    color: var(--p-300);
  }

  .form-date-today:hover {
    color: var(--p-200);
  }

  .form-date-error,
  .form-btn-remove {
    color: var(--r-200);
  }

  .form-btn-remove:hover {
    background: rgba(226, 75, 74, 0.15);
  }

  .form-btn-remove-wide {
    border-color: rgba(240, 149, 149, 0.4);
  }

  .form-btn-cancel:hover {
    background: var(--s-600);
  }

  .form-tile:focus-visible,
  .form-pill:focus-visible,
  .form-hint-undo:focus-visible,
  .form-section-toggle:focus-visible,
  .form-date-today:focus-visible,
  .form-btn-remove:focus-visible,
  .form-btn-cancel:focus-visible,
  .form-btn-save:focus-visible {
    outline-color: var(--p-300);
  }
}
</style>
