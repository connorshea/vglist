<template>
  <div class="library-edit-bar level">
    <div class="level-left">
      <span class="has-text-weight-bold pr-15">{{ selectedGamesString }}</span>
      <number-field
        :form-class="''"
        :field-class="'mb-0 mr-5'"
        :attribute="'rating'"
        :placeholder="'Rating (out of 100)'"
        :required="false"
        :max="100"
        :width="'200px'"
        v-model="updateData.rating"
      ></number-field>
      <static-single-select
        :placeholder="'Completion Status'"
        :grandparent-class="'field mb-0 mr-5'"
        v-model="updateData.completion_status"
        :options="FORMATTED_COMPLETION_STATUSES"
      ></static-single-select>
    </div>
    <div class="level-right">
      <button class="button is-fullwidth-mobile mr-5 mr-0-mobile" @click="closeEditBar">
        Cancel
      </button>
      <button
        class="button is-fullwidth-mobile is-primary mr-5 mr-0-mobile"
        :disabled="!updateButtonActive"
        @click="updateGames"
      >
        Update
      </button>
    </div>
  </div>
</template>

<script setup lang="ts">
import VglistUtils from "../utils";
import Turbolinks from "turbolinks";
import NumberField from "./fields/number-field.vue";
import StaticSingleSelect from "./fields/static-single-select.vue";
import { computed, reactive } from "vue";

interface Props {
  gamePurchases: any[];
}

const props = defineProps<Props>();

const emit = defineEmits(["closeEditBar"]);

// Reactive data
const updateData = reactive({
  ids: [] as number[],
  completion_status: null as any,
  rating: undefined as number | string | undefined,
});

// Methods
function closeEditBar() {
  emit("closeEditBar");
}

function updateGames(): void {
  // Reset the array to the currently-selected gamePurchases.
  updateData.ids = props.gamePurchases.map((gp) => gp.id);

  if (updateData.rating === undefined || updateData.rating === null) {
    delete (updateData as any).rating;
  }

  // Clone the object before we mess with the values.
  // This prevents the values in the edit bar from changing when these
  // values are changed.
  let updateDataCopy = { ...updateData };

  if (updateDataCopy.completion_status !== null) {
    (updateDataCopy as any).completion_status = updateDataCopy.completion_status.value;
  }

  VglistUtils.rawAuthenticatedFetch(
    "/game_purchases/bulk_update.json",
    "POST",
    JSON.stringify(updateDataCopy),
  ).then((response) => {
    if (response.ok) {
      // Redirects to self.
      Turbolinks.visit(window.location.href);
    } else {
      console.log("Add error handling, doofus.");
    }
  });
}

// Computed properties
const selectedGamesString = computed((): string => {
  let gpLength = props.gamePurchases.length;
  return `${gpLength} game${gpLength > 1 ? "s" : ""} selected`;
});

const updateButtonActive = computed((): boolean => {
  if (Object.keys(updateData).length === 1) {
    return false;
  }

  let returnBool = false;

  // Check if rating or completion status have values.
  // If they do, return true. Otherwise, return false.
  (["rating", "completion_status"] as const).forEach((attribute) => {
    const value = updateData[attribute];
    if (value !== undefined && value !== "" && value !== null) {
      returnBool = true;
    }
  });

  return returnBool;
});

const FORMATTED_COMPLETION_STATUSES = [
  { label: "Unplayed", value: "unplayed" },
  { label: "In Progress", value: "in_progress" },
  { label: "Paused", value: "paused" },
  { label: "Dropped", value: "dropped" },
  { label: "Completed", value: "completed" },
  { label: "100% Completed", value: "fully_completed" },
  { label: "N/A", value: "not_applicable" },
];
</script>
