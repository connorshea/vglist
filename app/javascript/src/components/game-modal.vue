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
            :max-height="'150px'"
            :disabled="true"
            @input="selectGame"
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
            :max-height="'150px'"
            @input="selectGame"
          ></single-select>
        </div>
      </section>
      <footer class="modal-card-foot">
        <button @click="onSave" class="button is-success js-submit-button">Save changes</button>
        <button @click="onClose" class="button">Cancel</button>
      </footer>
    </div>
  </div>
</template>

<script lang="ts">
import TextField from './fields/text-field.vue';
import TextArea from './fields/text-area.vue';
import NumberField from './fields/number-field.vue';
import DateField from './fields/date-field.vue';
import SingleSelect from './fields/single-select.vue';
import MultiSelect from './fields/multi-select.vue';
import StaticSingleSelect from './fields/static-single-select.vue';
import Rails from '@rails/ujs';

export default {
  name: 'game-modal',
  components: {
    TextField,
    TextArea,
    NumberField,
    DateField,
    SingleSelect,
    MultiSelect,
    StaticSingleSelect
  },
  props: {
    id: {
      type: Number,
      required: false
    },
    rating: {
      type: [Number, String],
      required: false,
      default: ''
    },
    hours_played: {
      type: [Number, String],
      required: false,
      default: ''
    },
    completion_status: {
      type: Object,
      required: false
    },
    start_date: {
      type: String,
      required: false
    },
    completion_date: {
      type: String,
      required: false
    },
    comments: {
      type: String,
      required: false,
      default: ''
    },
    platforms: {
      type: Array,
      required: false,
      default: function() {
        return [];
      }
    },
    stores: {
      type: Array,
      required: false,
      default: function() {
        return [];
      }
    },
    game: {
      type: Object,
      required: false,
      default: function() {
        return {};
      }
    },
    userId: {
      type: Number,
      required: true
    },
    isActive: {
      type: Boolean,
      required: true
    },
    gameModalState: {
      type: String,
      required: true,
      validator: val => ['create', 'update', 'createWithGame'].includes(val)
    }
  },
  data() {
    return {
      errors: [],
      gamePurchase: {
        comments: this.$props.comments,
        rating: this.$props.rating,
        game: this.$props.game,
        userId: this.$props.userId,
        completion_status: this.$props.completion_status,
        start_date: this.$props.start_date,
        hours_played: parseFloat(this.$props.hours_played),
        completion_date: this.$props.completion_date,
        platforms: this.$props.platforms,
        stores: this.$props.stores
      },
      formData: {
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
      },
      gameSelected: this.$props.gameModalState !== 'create',
      completionStatuses: {
        unplayed: 'Unplayed',
        in_progress: 'In Progress',
        paused: 'Paused',
        dropped: 'Dropped',
        completed: 'Completed',
        fully_completed: '100% Completed',
        not_applicable: 'N/A'
      }
    };
  },
  methods: {
    onClose() {
      this.$emit('close');
    },
    onSave() {
      let submittableData = {
        game_purchase: {
          game_id: this.gamePurchase.game.id,
          user_id: this.gamePurchase.userId
        }
      };

      if (this.gamePurchase.comments) {
        submittableData['game_purchase'][
          'comments'
        ] = this.gamePurchase.comments;
      }

      if (this.gamePurchase.rating !== '') {
        submittableData['game_purchase']['rating'] = this.gamePurchase.rating;
      }

      if (this.gamePurchase.hours_played !== '') {
        submittableData['game_purchase'][
          'hours_played'
        ] = this.gamePurchase.hours_played;
      }

      if (
        this.gamePurchase.completion_status !== null &&
        this.gamePurchase.completion_status !== '' &&
        typeof this.gamePurchase.completion_status !== 'undefined'
      ) {
        submittableData['game_purchase'][
          'completion_status'
        ] = this.gamePurchase.completion_status.value;
      }

      if (
        this.gamePurchase.start_date !== '' &&
        this.gamePurchase.start_date !== null
      ) {
        submittableData['game_purchase'][
          'start_date'
        ] = this.gamePurchase.start_date;
      }

      if (
        this.gamePurchase.completion_date !== '' &&
        this.gamePurchase.completion_date !== null
      ) {
        submittableData['game_purchase'][
          'completion_date'
        ] = this.gamePurchase.completion_date;
      }

      if (this.gamePurchase.platforms !== []) {
        submittableData['game_purchase']['platform_ids'] = Array.from(
          this.gamePurchase.platforms,
          (platform: { id: String }) => platform.id
        );
      }

      if (this.gamePurchase.stores !== []) {
        submittableData['game_purchase']['store_ids'] = Array.from(
          this.gamePurchase.stores,
          (store: { id: String }) => store.id
        );
      }

      // If any of these properties are undefined, set them to null.
      ['comments', 'rating', 'hours_played', 'completion_status', 'start_date', 'completion_date'].forEach((property) => {
        // Set it to a blank string if the property is comments, and null otherwise.
        let value = property === 'comments' ? "" : null;

        if (submittableData['game_purchase'][property] === undefined) {
          submittableData['game_purchase'][property] = value;
        }
      });

      let method;
      if (
        this.gameModalState === 'create' ||
        this.gameModalState === 'createWithGame'
      ) {
        method = 'POST';
      } else if (this.gameModalState === 'update') {
        method = 'PUT';
      }

      fetch(this.gamePurchasesSubmitUrl, {
        method: method,
        body: JSON.stringify(submittableData),
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': Rails.csrfToken(),
          Accept: 'application/json'
        },
        credentials: 'same-origin'
      })
        .then(response => {
          return response.json().then(json => {
            if (response.ok) {
              return Promise.resolve(json);
            }
            return Promise.reject(json);
          });
        })
        .then(gamePurchase => {
          this.$emit('create', gamePurchase);
          this.$emit('closeAndRefresh');
        })
        .catch(errors => {
          this.errors = errors;
          let submitButton = document.querySelector('.js-submit-button');
          submitButton.classList.add('js-submit-button-error');
          setTimeout(() => {
            submitButton.classList.remove('js-submit-button-error');
          }, 2000);
        });
    },
    selectGame() {
      this.gameSelected = true;
    }
  },
  computed: {
    gamePurchasesSubmitUrl: function() {
      return this.gameModalState === 'update'
        ? `/game_purchases/${this.id}`
        : '/game_purchases';
    },
    modalTitle: function() {
      return this.gamePurchase.game.name !== undefined
        ? this.gamePurchase.game.name
        : 'Add a game to your library';
    },
    formattedCompletionStatuses: function() {
      return Object.entries(this.completionStatuses).map(status => {
        return { label: status[1], value: status[0] };
      });
    }
  }
};
</script>
