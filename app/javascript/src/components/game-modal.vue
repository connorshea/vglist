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

          <number-field
            :form-class="formData.class"
            :attribute="formData.rating.attribute"
            :label="formData.rating.label"
            :required="false"
            v-model="gamePurchase.rating"
          ></number-field>

          <text-field
            :form-class="formData.class"
            :attribute="formData.comments.attribute"
            :label="formData.comments.label"
            :required="false"
            v-model="gamePurchase.comments"
          ></text-field>
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
import SingleSelect from './fields/single-select.vue';
import Rails from 'rails-ujs';

export default {
  name: 'game-modal',
  components: {
    TextField,
    NumberField,
    SingleSelect
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
        userId: this.userId
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
        game: {
          label: 'Game'
        }
      },
      gamePurchaseSelected: !this.create
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
      if (this.gamePurchase.rating != '') {
        submittableData['game_purchase']['rating'] = this.gamePurchase.rating;
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
    }
  }
}
</script>
