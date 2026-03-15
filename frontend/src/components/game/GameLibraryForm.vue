<template>
  <div class="form-card">
    <div class="form-grid">
      <!-- Left column: Status, Rating, Dates -->
      <div class="form-col form-col-left">
        <div class="form-group">
          <label class="form-label">Status</label>
          <div class="form-pills">
            <button
              v-for="opt in statusOptions"
              :key="opt.value"
              type="button"
              class="form-pill"
              :class="formStatus === opt.value ? 'form-pill-on' : 'form-pill-off'"
              @click="formStatus = formStatus === opt.value ? null : opt.value"
            >
              {{ opt.label }}
            </button>
          </div>
        </div>

        <div class="form-group">
          <label class="form-label" for="form-rating">Rating (out of 100)</label>
          <div class="form-rating-row">
            <input
              id="form-rating"
              v-model.number="formRating"
              type="number"
              min="0"
              max="100"
              class="form-rating-input"
              @input="clampRating"
            />
            <div class="form-rating-track" @click="setRatingFromClick">
              <div class="form-rating-fill" :style="{ width: (formRating ?? 0) + '%' }"></div>
            </div>
          </div>
        </div>

        <div class="form-group">
          <label class="form-label" for="form-hours-played">Hours played</label>
          <input
            id="form-hours-played"
            v-model.number="formHoursPlayed"
            type="number"
            min="0"
            step="0.1"
            class="form-hours-input"
            placeholder="0"
          />
        </div>

        <div class="form-dates">
          <div class="form-date-field">
            <div class="form-label-row">
              <label class="form-label" for="form-start-date">Started</label>
              <button type="button" class="form-date-today" @click="formStartDate = today">Today</button>
            </div>
            <input id="form-start-date" v-model="formStartDate" type="date" class="form-date-input" :max="today" />
          </div>
          <div class="form-date-field">
            <div class="form-label-row">
              <label class="form-label" for="form-completion-date">Finished</label>
              <button type="button" class="form-date-today" @click="formCompletionDate = today">Today</button>
            </div>
            <input
              id="form-completion-date"
              v-model="formCompletionDate"
              type="date"
              class="form-date-input"
              :max="today"
            />
          </div>
        </div>
        <p v-if="dateValidationError" class="form-date-error">
          {{ dateValidationError }}
        </p>
      </div>

      <!-- Right column: Platforms, Store, Notes, Actions -->
      <div class="form-col form-col-right">
        <div class="form-group">
          <label class="form-label">Platforms played</label>
          <div class="form-pills">
            <button
              v-for="plat in gamePlatforms"
              :key="plat.id"
              type="button"
              class="form-pill"
              :class="formPlatformIds.has(plat.id) ? 'form-pill-on' : 'form-pill-off'"
              @click="toggleFormPlatform(plat.id)"
            >
              {{ plat.name }}
            </button>
            <span v-if="gamePlatforms.length === 0" class="form-empty-hint"> No platforms listed for this game. </span>
          </div>
        </div>

        <div class="form-group">
          <label class="form-label">Store</label>
          <div class="form-pills">
            <button
              v-for="store in allStores"
              :key="store.id"
              type="button"
              class="form-pill"
              :class="formStoreIds.has(store.id) ? 'form-pill-on' : 'form-pill-off'"
              @click="toggleFormStore(store.id)"
            >
              {{ store.name }}
            </button>
            <span v-if="storesLoading" class="form-empty-hint"> Loading stores... </span>
          </div>
        </div>

        <div class="form-group form-notes-group">
          <label class="form-label" for="form-comments">Review / notes</label>
          <textarea
            id="form-comments"
            v-model="formComments"
            class="form-textarea"
            placeholder="What did you think?"
            maxlength="2000"
          ></textarea>
        </div>

        <div class="form-actions">
          <button
            v-if="isEditing"
            type="button"
            class="form-btn-remove"
            :disabled="removingFromLibrary"
            @click="$emit('requestRemove')"
          >
            {{ removingFromLibrary ? "Removing\u2026" : "Remove" }}
          </button>
          <div class="form-actions-right">
            <button type="button" class="form-btn-cancel" @click="$emit('cancel')">Cancel</button>
            <button type="button" class="form-btn-save" :disabled="saving || !!dateValidationError" @click="submit">
              {{ saving ? "Saving\u2026" : "Save" }}
            </button>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { computed, ref, watch } from "vue";
import { gqlClient } from "@/graphql/client";
import { GET_GAME_PURCHASE } from "@/graphql/queries/games";
import { ADD_GAME_TO_LIBRARY, UPDATE_GAME_IN_LIBRARY } from "@/graphql/mutations/games";
import type { GetGamePurchaseQuery, GamePurchaseCompletionStatus } from "@/types/graphql";
import { extractGqlError } from "@/utils/graphql-errors";

const props = defineProps<{
  gameId: string;
  gameName: string;
  gamePurchaseId: string | null;
  gamePlatforms: { id: string; name: string }[];
  allStores: { id: string; name: string }[];
  storesLoading: boolean;
  removingFromLibrary: boolean;
}>();

const emit = defineEmits<{
  cancel: [];
  saved: [message: string];
  requestRemove: [];
  error: [message: string];
}>();

const statusOptions: { value: GamePurchaseCompletionStatus; label: string }[] = [
  { value: "UNPLAYED", label: "Unplayed" },
  { value: "IN_PROGRESS", label: "Playing" },
  { value: "PAUSED", label: "Paused" },
  { value: "DROPPED", label: "Dropped" },
  { value: "COMPLETED", label: "Completed" },
  { value: "FULLY_COMPLETED", label: "100%" },
  { value: "NOT_APPLICABLE", label: "N/A" }
];

const formStatus = ref<GamePurchaseCompletionStatus | null>(null);
const formRating = ref<number | null>(null);
const formStartDate = ref("");
const formCompletionDate = ref("");
const today = computed(() => new Date().toISOString().slice(0, 10));
const formPlatformIds = ref(new Set<string>());
const formStoreIds = ref(new Set<string>());
const formHoursPlayed = ref<number | null>(null);
const formComments = ref("");
const isEditing = ref(false);
const saving = ref(false);

// ── localStorage draft persistence ──
let suppressDraftSync = false;

function reviewDraftKey(): string {
  return `vglist-review-draft-${props.gameId}`;
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
  formStartDate.value = "";
  formCompletionDate.value = "";
  formPlatformIds.value = new Set();
  formStoreIds.value = new Set();
  formComments.value = "";
  isEditing.value = false;
}

function openAsAdd() {
  suppressDraftSync = true;
  resetForm();
  suppressDraftSync = false;
  loadReviewDraft();
}

async function openAsEdit() {
  const purchaseId = props.gamePurchaseId;
  if (!purchaseId) return;

  suppressDraftSync = true;
  resetForm();
  isEditing.value = true;

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
    formStartDate.value = gp.startDate ?? "";
    formCompletionDate.value = gp.completionDate ?? "";
    formComments.value = gp.comments ?? "";
    suppressDraftSync = false;
    loadReviewDraft();
    formPlatformIds.value = new Set(gp.platforms.nodes.map((p) => p.id));
    formStoreIds.value = new Set(gp.stores.nodes.map((s) => s.id));
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

function setRatingFromClick(event: MouseEvent) {
  const track = event.currentTarget as HTMLElement;
  const rect = track.getBoundingClientRect();
  const pct = ((event.clientX - rect.left) / rect.width) * 100;
  formRating.value = Math.round(Math.min(100, Math.max(0, pct)));
}

const dateValidationError = computed(() => {
  const todayStr = today.value;
  if (formStartDate.value && formStartDate.value > todayStr) {
    return "Start date cannot be in the future.";
  }
  if (formCompletionDate.value && formCompletionDate.value > todayStr) {
    return "Completion date cannot be in the future.";
  }
  if (formStartDate.value && formCompletionDate.value) {
    if (formStartDate.value > formCompletionDate.value) {
      return "Start date must be on or before the completion date.";
    }
  }
  return "";
});

function buildFormVariables(): Record<string, unknown> {
  const variables: Record<string, unknown> = {};

  if (formStatus.value) {
    variables.completionStatus = formStatus.value;
  }
  if (formRating.value != null && formRating.value >= 0) {
    variables.rating = Math.round(Math.min(100, Math.max(0, formRating.value)));
  }
  if (formHoursPlayed.value != null && formHoursPlayed.value >= 0) {
    variables.hoursPlayed = formHoursPlayed.value;
  }
  if (formStartDate.value) {
    variables.startDate = formStartDate.value;
  }
  if (formCompletionDate.value) {
    variables.completionDate = formCompletionDate.value;
  }
  if (formPlatformIds.value.size > 0) {
    variables.platforms = [...formPlatformIds.value];
  }
  if (formStoreIds.value.size > 0) {
    variables.stores = [...formStoreIds.value];
  }
  if (formComments.value.trim()) {
    variables.comments = formComments.value.trim();
  }

  return variables;
}

async function submit() {
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

defineExpose({ openAsAdd, openAsEdit });
</script>

<style scoped>
/* ── Inline form ── */
.form-card {
  background: var(--color-surface);
  border-radius: var(--radius-lg);
  overflow: hidden;
  color: var(--color-text-primary);
}

.form-grid {
  display: grid;
  grid-template-columns: minmax(0, 1fr) minmax(0, 1.2fr);
}

.form-col {
  padding: 1.25rem;
}

.form-col-left {
  border-right: 1px solid var(--color-border);
}

.form-col-right {
  display: flex;
  flex-direction: column;
}

.form-group {
  margin-bottom: 1rem;
}

.form-label {
  display: block;
  font-size: 0.75rem;
  color: var(--color-text-secondary);
  margin-bottom: 0.4rem;
}

/* Form pills */
.form-pills {
  display: flex;
  flex-wrap: wrap;
  gap: 0.25rem;
}

.form-pill {
  font-size: 0.75rem;
  padding: 0.3rem 0.75rem;
  border-radius: var(--radius-pill);
  cursor: pointer;
  transition: all 0.15s;
  display: inline-block;
  user-select: none;
  border: none;
  background: none;
  font-family: inherit;
}

.form-pill-off {
  background: transparent;
  border: 1px solid var(--color-border);
  color: var(--color-text-secondary);
}

.form-pill-off:hover {
  border-color: var(--color-text-secondary);
  color: var(--color-text-primary);
}

.form-pill-on {
  background: var(--p-100);
  color: var(--p-700);
  font-weight: 500;
  border: 1px solid var(--p-100);
}

.form-empty-hint {
  font-size: 0.75rem;
  color: var(--color-text-tertiary);
  font-style: italic;
}

/* Rating input */
.form-rating-row {
  display: flex;
  align-items: center;
  gap: 0.5rem;
}

.form-rating-input {
  width: 56px;
  font-size: 0.8rem;
  text-align: center;
  border: 1px solid var(--color-border);
  border-radius: var(--radius-md);
  padding: 0.35rem 0.5rem;
  outline: none;
  font-family: inherit;
}

.form-rating-input:focus {
  border-color: var(--color-text-secondary);
}

.form-rating-track {
  flex: 1;
  height: 6px;
  border-radius: 3px;
  background: var(--p-100);
  overflow: hidden;
  cursor: pointer;
}

.form-rating-fill {
  height: 100%;
  border-radius: 3px;
  background: var(--p-500);
  transition: width 0.15s;
}

/* Date inputs */
.form-dates {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 0.625rem;
}

.form-date-input {
  width: 100%;
  font-size: 0.75rem;
  border: 1px solid var(--color-border);
  border-radius: var(--radius-md);
  padding: 0.35rem 0.5rem;
  outline: none;
  font-family: inherit;
}

.form-date-input:focus {
  border-color: var(--color-text-secondary);
}

.form-label-row {
  display: flex;
  justify-content: space-between;
  align-items: baseline;
}

.form-label-row .form-label {
  margin-bottom: 0;
}

.form-date-today {
  font-size: 0.7rem;
  font-weight: 600;
  color: var(--p-500);
  background: none;
  border: none;
  padding: 0;
  cursor: pointer;
  font-family: inherit;
  margin-bottom: 0.4rem;
}

.form-date-today:hover {
  color: var(--p-600);
  text-decoration: underline;
}

.form-date-error {
  color: #cc0000;
  font-size: 0.75rem;
  margin-top: 0.25rem;
}

/* Hours played input */
.form-hours-input {
  width: 80px;
  font-size: 0.8rem;
  border: 1px solid var(--color-border);
  border-radius: var(--radius-md);
  padding: 0.35rem 0.5rem;
  outline: none;
  font-family: inherit;
}

.form-hours-input:focus {
  border-color: var(--color-text-secondary);
}

/* Notes textarea */
.form-notes-group {
  flex: 1;
  display: flex;
  flex-direction: column;
}

.form-textarea {
  width: 100%;
  font-size: 0.8rem;
  border: 1px solid var(--color-border);
  border-radius: var(--radius-md);
  padding: 0.5rem 0.625rem;
  outline: none;
  resize: vertical;
  min-height: 80px;
  font-family: inherit;
}

.form-textarea:focus {
  border-color: var(--color-text-secondary);
}

/* Form action buttons */
.form-actions {
  display: flex;
  gap: 0.5rem;
  justify-content: space-between;
  align-items: center;
  padding-top: 0.75rem;
}

.form-actions-right {
  display: flex;
  gap: 0.5rem;
}

.form-btn-remove {
  color: #c0392b;
  font-size: 0.8rem;
  background: none;
  border: 1px solid #e8c4c0;
  border-radius: var(--radius-md);
  padding: 0.5rem 1rem;
  cursor: pointer;
  font-family: inherit;
}

.form-btn-remove:hover {
  background: #fdf0ef;
  border-color: #c0392b;
}

.form-btn-remove:disabled {
  opacity: 0.6;
  cursor: not-allowed;
}

.form-btn-cancel {
  color: var(--color-text-secondary);
  font-size: 0.8rem;
  background: none;
  border: 1px solid var(--color-border);
  border-radius: var(--radius-md);
  padding: 0.5rem 1rem;
  cursor: pointer;
  font-family: inherit;
}

.form-btn-cancel:hover {
  background: var(--color-bg-subtle);
}

.form-btn-save {
  background: var(--p-500);
  color: #fff;
  font-size: 0.8rem;
  border: none;
  border-radius: var(--radius-md);
  padding: 0.5rem 1.25rem;
  cursor: pointer;
  font-family: inherit;
}

.form-btn-save:hover {
  background: var(--p-600);
}

.form-btn-save:disabled {
  opacity: 0.6;
  cursor: not-allowed;
}

/* ── Responsive ── */
@media (max-width: 768px) {
  .form-grid {
    grid-template-columns: 1fr;
  }

  .form-col-left {
    border-right: none;
    border-bottom: 1px solid var(--color-border);
  }
}

/* ── Dark mode ── */
@media (prefers-color-scheme: dark) {
  .form-card {
    border: 1px solid var(--s-300);
  }

  .form-pill-on {
    background: rgba(206, 203, 246, 0.12);
    color: var(--p-200);
  }

  .form-rating-track {
    background: rgba(157, 153, 224, 0.15);
  }

  .form-rating-fill {
    background: var(--p-400);
  }

  .form-rating-input,
  .form-hours-input,
  .form-date-input,
  .form-textarea {
    background: var(--s-600);
    color: var(--s-50);
  }

  .form-rating-input::placeholder,
  .form-hours-input::placeholder,
  .form-date-input::placeholder,
  .form-textarea::placeholder {
    color: var(--s-300);
  }

  .form-btn-remove {
    background: rgba(226, 75, 74, 0.15);
    color: var(--r-200);
    border-color: transparent;
  }

  .form-btn-remove:hover {
    background: rgba(226, 75, 74, 0.25);
    border-color: transparent;
  }

  .form-date-error {
    color: var(--r-200);
  }

  .form-date-today {
    color: var(--p-300);
  }

  .form-date-today:hover {
    color: var(--p-200);
  }
}
</style>
