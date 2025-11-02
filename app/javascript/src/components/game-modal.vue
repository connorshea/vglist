<template>
  <div class="modal" :class="{ 'is-active': isActive }">
    <div @click="onClose" class="modal-background"></div>
    <div class="modal-card">
      <header class="modal-card-head">
        <p class="modal-card-title">{{ modalTitle }}</p>
        <button @click="onClose" class="delete" aria-label="close"></button>
      </header>
      <section class="modal-card-body modal-card-body-allow-overflow">
        <!-- Display errors if there are any. -->
        <div class="notification errors-notification is-danger" v-if="errors.length > 0">
          <p>
            {{ errors.length > 1 ? 'Errors' : 'An error' }} prevented this game from
            being added to your library:
          </p>
          <ul>
            <li v-for="error in errors" :key="error">{{ error }}</li>
          </ul>
        </div>
        <div v-if="gameSelected">
          <single-select
            :label="formData.game.label"
            v-model="gamePurchase.game"
            :search-path-identifier="'games'"
            :disabled="true"
            @update:modelValue="selectGame"
          ></single-select>

          <static-single-select
            :label="formData.completionStatus.label"
            v-model="gamePurchase.completion_status"
            :options="formattedCompletionStatuses"
          ></static-single-select>

          <number-field
            :form-class="formData.class"
            :attribute="formData.rating.attribute"
            :label="formData.rating.label"
            :required="false"
            :max="100"
            v-model="gamePurchase.rating"
          ></number-field>

          <number-field
            :form-class="formData.class"
            :attribute="formData.hoursPlayed.attribute"
            :label="formData.hoursPlayed.label"
            :required="false"
            v-model="gamePurchase.hours_played"
          ></number-field>

          <number-field
            :form-class="formData.class"
            :attribute="formData.replayCount.attribute"
            :label="formData.replayCount.label"
            :required="false"
            v-model="gamePurchase.replay_count"
          ></number-field>

          <text-area
            :form-class="formData.class"
            :attribute="formData.comments.attribute"
            :label="formData.comments.label"
            :required="false"
            v-model="gamePurchase.comments"
          ></text-area>

          <date-field
            :form-class="formData.class"
            :attribute="formData.startDate.attribute"
            :label="formData.startDate.label"
            :required="false"
            v-model="gamePurchase.start_date"
          ></date-field>

          <date-field
            :form-class="formData.class"
            :attribute="formData.completionDate.attribute"
            :label="formData.completionDate.label"
            :required="false"
            v-model="gamePurchase.completion_date"
          ></date-field>

          <multi-select
            :label="formData.platforms.label"
            v-model="gamePurchase.platforms"
            :search-path-identifier="'platforms'"
          ></multi-select>

          <multi-select
            :label="formData.stores.label"
            v-model="gamePurchase.stores"
            :search-path-identifier="'stores'"
          ></multi-select>
        </div>

        <div v-else>
          <single-select
            :label="formData.game.label"
            v-model="gamePurchase.game"
            :search-path-identifier="'games'"
            @update:modelValue="selectGame"
          ></single-select>
        </div>
      </section>
      <footer class="modal-card-foot">
        <button @click="onSave" class="button is-primary js-submit-button">Save changes</button>
        <button @click="onClose" class="button ml-10">Cancel</button>
      </footer>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, computed } from 'vue';
import TextArea from './fields/text-area.vue';
import NumberField from './fields/number-field.vue';
import DateField from './fields/date-field.vue';
import SingleSelect from './fields/single-select.vue';
import MultiSelect from './fields/multi-select.vue';
import StaticSingleSelect from './fields/static-single-select.vue';
import VglistUtils from '../utils';
import type { CompletionStatus } from '../types';

const completionStatuses: Record<CompletionStatus, string> = {
  unplayed: 'Unplayed',
  in_progress: 'In Progress',
  paused: 'Paused',
  dropped: 'Dropped',
  completed: 'Completed',
  fully_completed: '100% Completed',
  not_applicable: 'N/A'
};

interface GamePurchaseSubmittableData {
  game_purchase: {
    game_id: number;
    user_id: number;
    comments?: string;
    rating?: number | string | null;
    hours_played?: number | string | null;
    replay_count?: number | string | null;
    completion_status?: string | null;
    start_date?: string | null;
    completion_date?: string | null;
    platform_ids?: Array<string | number>;
    store_ids?: Array<string | number>;
  };
}

interface Props {
  id?: number;
  rating?: number | string;
  hours_played?: number | string;
  replay_count?: number | string;
  // TODO: Need to improve this type so we can pass typechecking.
  completion_status?: Record<string, any>;
  start_date?: string;
  completion_date?: string;
  comments?: string;
  platforms?: Array<{ id: string | number }>;
  stores?: Array<{ id: string | number }>;
  // TODO: Improve this type.
  game?: Record<string, any>;
  userId: number;
  isActive: boolean;
  gameModalState: 'create' | 'update' | 'createWithGame';
}

// TODO: replace withDefaults after Vue 3.5 upgrade.
// https://vuejs.org/guide/components/props.html#reactive-props-destructure
const props = withDefaults(defineProps<Props>(), {
  rating: '',
  hours_played: '',
  replay_count: 0,
  comments: '',
  platforms: () => [],
  stores: () => [],
  game: () => ({}),
});

const emit = defineEmits(['close', 'create', 'closeAndRefresh']);

const errors = ref<string[]>([]);

const gamePurchase = ref({
  comments: props.comments,
  rating: props.rating,
  game: props.game,
  userId: props.userId,
  completion_status: props.completion_status,
  start_date: props.start_date,
  hours_played: typeof props.hours_played === 'string' ? parseFloat(props.hours_played) : props.hours_played,
  replay_count: props.replay_count,
  completion_date: props.completion_date,
  platforms: props.platforms as Array<{ id: string | number }>,
  stores: props.stores as Array<{ id: string | number }>
});

const formData = {
  class: 'game_purchase',
  comments: {
    label: 'Comments',
    attribute: 'comments'
  },
  rating: {
    label: 'Rating (out of 100)',
    attribute: 'rating'
  },
  hoursPlayed: {
    label: 'Hours Played',
    attribute: 'hours_played'
  },
  replayCount: {
    label: 'Replay Count',
    attribute: 'replay_count'
  },
  completionStatus: {
    label: 'Completion Status'
  },
  startDate: {
    label: 'Start Date',
    attribute: 'start_date'
  },
  completionDate: {
    label: 'Completion Date',
    attribute: 'completion_date'
  },
  platforms: {
    label: 'Platforms'
  },
  stores: {
    label: 'Stores'
  },
  game: {
    label: 'Game'
  }
};

const gameSelected = ref(props.gameModalState !== 'create');

const gamePurchasesSubmitUrl = computed(() => {
  return props.gameModalState === 'update'
    ? `/game_purchases/${props.id}`
    : '/game_purchases';
});

const modalTitle = computed(() => {
  return gamePurchase.value.game.name !== undefined
    ? gamePurchase.value.game.name
    : 'Add a game to your library';
});

const formattedCompletionStatuses = computed(() => {
  return Object.entries(completionStatuses).map(status => {
    return { label: status[1], value: status[0] };
  });
});

function onClose() {
  emit('close');
}

function onSave() {
  const gp = gamePurchase.value;
  const submittableData: GamePurchaseSubmittableData = {
    game_purchase: {
      game_id: gp.game.id,
      user_id: gp.userId
    }
  };

  if (gp.comments) {
    submittableData.game_purchase.comments = gp.comments;
  }

  if (gp.rating) {
    submittableData.game_purchase.rating = gp.rating;
  }

  if (
    (typeof gp.hours_played === 'string' && gp.hours_played !== '') ||
    (typeof gp.hours_played === 'number' && !isNaN(gp.hours_played))
  ) {
    submittableData.game_purchase.hours_played = gp.hours_played;
  }

  if (
    gp.replay_count !== '' &&
    gp.replay_count !== null &&
    typeof gp.replay_count !== 'undefined'
  ) {
    submittableData.game_purchase.replay_count = gp.replay_count;
  }

  if (
    gp.completion_status && typeof gp.completion_status.value !== 'undefined'
  ) {
    submittableData.game_purchase.completion_status = gp.completion_status.value;
  }

  if (
    gp.start_date !== '' &&
    gp.start_date !== null
  ) {
    submittableData.game_purchase.start_date = gp.start_date;
  }

  if (
    gp.completion_date !== '' &&
    gp.completion_date !== null
  ) {
    submittableData.game_purchase.completion_date = gp.completion_date;
  }

  if (gp.platforms.length !== 0) {
    submittableData.game_purchase.platform_ids = Array.from(
      gp.platforms as Array<{ id: string | number }>,
      (platform) => platform.id
    );
  }

  if (gp.stores.length !== 0) {
    submittableData.game_purchase.store_ids = Array.from(
      gp.stores as Array<{ id: string | number }>,
      (store) => store.id
    );
  }

  (['comments', 'rating', 'hours_played', 'completion_status', 'start_date', 'completion_date'] as Array<keyof GamePurchaseSubmittableData['game_purchase']>).forEach((property) => {
    let value = property === 'comments' ? "" : null;
    if (typeof submittableData.game_purchase[property] === 'undefined') {
      (submittableData.game_purchase as any)[property] = value;
    }
  });

  if (submittableData.game_purchase.replay_count === undefined) {
    submittableData.game_purchase.replay_count = 0;
  }

  let method: 'POST' | 'PUT' = 'POST';
  if (
    props.gameModalState === 'create' ||
    props.gameModalState === 'createWithGame'
  ) {
    method = 'POST';
  } else if (props.gameModalState === 'update') {
    method = 'PUT';
  }

  VglistUtils.authenticatedFetch(
    gamePurchasesSubmitUrl.value,
    method,
    JSON.stringify(submittableData)
  ).then(gamePurchase => {
      emit('create', gamePurchase);
      emit('closeAndRefresh');
    })
    .catch(errorsResp => {
      errors.value = errorsResp;
      const submitButton = document.querySelector('.js-submit-button');
      if (submitButton) {
        // Add a class to the button to indicate an error, then remove it.
        submitButton.classList.add('js-submit-button-error');
        setTimeout(() => {
          submitButton.classList.remove('js-submit-button-error');
        }, 2000);
      }
    });
}

function selectGame() {
  gameSelected.value = true;
}

</script>
