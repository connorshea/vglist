<template>
  <div class="modal" :class="{ 'is-active': isActive } ">
    <div @click="onClose" class="modal-background"></div>
    <div class="modal-card modal-card-allow-overflow">
      <header class="modal-card-head">
        <p class="modal-card-title">{{ modalTitle }}</p>
        <button @click="onClose" class="delete" aria-label="close"></button>
      </header>
      <section class="modal-card-body modal-card-body-allow-overflow">
        <div v-if="gamePurchaseSelected">
          <single-select
            :label="formData.game.label"
            v-model="gamePurchase.game"
            :search-path-identifier="'games'"
            :max-height="'150px'"
            :disabled="true"
            @input="selectGamePurchase"
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
            v-model="gamePurchase.rating"
          ></number-field>

          <number-field
            :form-class="formData.class"
            :attribute="formData.hoursPlayed.attribute"
            :label="formData.hoursPlayed.label"
            :required="false"
            v-model="gamePurchase.hours_played"
          ></number-field>

          <text-field
            :form-class="formData.class"
            :attribute="formData.comments.attribute"
            :label="formData.comments.label"
            :required="false"
            v-model="gamePurchase.comments"
          ></text-field>

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
        </div>

        <div v-else>
          <single-select
            :label="formData.game.label"
            v-model="gamePurchase.game"
            :search-path-identifier="'games'"
            :max-height="'150px'"
            @input="selectGamePurchase"
          ></single-select>
        </div>

      </section>
      <footer class="modal-card-foot">
        <button @click="onSave" class="button is-success">Save changes</button>
        <button @click="onClose" class="button">Cancel</button>
      </footer>
    </div>
  </div>
</template>

<script>
import TextField from './fields/text-field.vue';
import NumberField from './fields/number-field.vue';
import DateField from './fields/date-field.vue';
import SingleSelect from './fields/single-select.vue';
import StaticSingleSelect from './fields/static-single-select.vue';
import Rails from 'rails-ujs';

export default {
  name: 'game-modal',
  components: {
    TextField,
    NumberField,
    DateField,
    SingleSelect,
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
    game: {
      type: Object,
      required: false,
      default: function() {
        return {}
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
    create: {
      type: Boolean,
      required: true
    }
  },
  data() {
    return {
      gamePurchase: {
        comments: this.comments,
        rating: this.rating,
        game: this.game,
        userId: this.userId,
        completion_status: this.completion_status,
        start_date: this.start_date,
        completion_date: this.completion_date
      },
      formData: {
        class: 'game_purchase',
        comments: {
          label: 'Comments',
          attribute: 'comments'
        },
        rating: {
          label: 'Rating',
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
        game: {
          label: 'Game'
        }
      },
      gamePurchaseSelected: !this.create,
      completionStatuses: {
        'unplayed': 'Unplayed',
        'in_progress': 'In Progress',
        'dropped': 'Dropped',
        'completed': 'Completed',
        'fully_completed': '100% Completed',
        'not_applicable': 'N/A'
      }
    }
  },
  methods: {
    onClose() {
      this.$emit('close');
    },
    onSave() {
      let submittableData = { game_purchase: {
        game_id: this.gamePurchase.game.id,
        user_id: this.gamePurchase.userId
      }};

      if (this.gamePurchase.comments) {
        submittableData['game_purchase']['comments'] = this.gamePurchase.comments;
      }
      if (this.gamePurchase.rating !== '') {
        submittableData['game_purchase']['rating'] = this.gamePurchase.rating;
      }
      if (this.gamePurchase.hours_played !== '') {
        submittableData['game_purchase']['hours_played'] = this.gamePurchase.hours_played;
      }
      if (this.gamePurchase.completion_status !== '') {
        submittableData['game_purchase']['completion_status'] = this.gamePurchase.completion_status.value;
      }
      if (this.gamePurchase.start_date !== '' && this.gamePurchase.start_date !== null) {
        submittableData['game_purchase']['start_date'] = this.gamePurchase.start_date;
      }
      if (this.gamePurchase.completion_date !== '' && this.gamePurchase.completion_date !== null) {
        submittableData['game_purchase']['completion_date'] = this.gamePurchase.completion_date;
      }

      fetch(this.gamePurchasesSubmitUrl, {
        method: this.create ? 'POST' : 'PUT',
        body: JSON.stringify(submittableData),
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': Rails.csrfToken(),
          'Accept': 'application/json'
        },
        credentials: 'same-origin'
      }).then((response) => {
        if (response.ok) {
          this.$emit('create');
          this.$emit('closeAndRefresh');
        }
      })
    },
    selectGamePurchase() {
      this.gamePurchaseSelected = true;
    }
  },
  computed: {
    gamePurchasesSubmitUrl: function() {
      return this.create ? '/game_purchases' : `/game_purchases/${this.id}`;
    },
    modalTitle: function() {
      return this.gamePurchase.game.name !== undefined ? this.gamePurchase.game.name : 'Add a game to your library';
    },
    formattedCompletionStatuses: function() {
      return Object.entries(this.completionStatuses).map(status => {
        return { label: status[1], value: status[0] };
      });
    }
  }
}
</script>
