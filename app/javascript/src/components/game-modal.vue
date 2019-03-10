<template>
  <div class="modal" :class="{ 'is-active': isActive } ">
    <div @click="onClose" class="modal-background"></div>
    <div class="modal-card">
      <header class="modal-card-head">
        <p class="modal-card-title">{{ modalTitle }}</p>
        <button @click="onClose" class="delete" aria-label="close"></button>
      </header>
      <section class="modal-card-body">
        <div v-if="gamePurchaseSelected">
          <text-field
            :form-class="formData.class"
            :attribute="formData.comment.attribute"
            :label="formData.comment.label"
            :required="false"
            v-model="gamePurchase.comment"
          ></text-field>
        </div>
        <div v-else>
          <single-select
            :label="formData.game.label"
            v-model="gamePurchase.game"
            :search-path-identifier="'games'"
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
import TextField from './text-field.vue';
import SingleSelect from './single-select.vue';
import Rails from 'rails-ujs';

export default {
  name: 'game-modal',
  components: {
    TextField,
    SingleSelect
  },
  props: {
    id: {
      type: Number,
      required: false
    },
    score: {
      type: Number,
      required: false
    },
    comment: {
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
        comment: this.comment,
        score: this.score,
        game: this.game,
        userId: this.userId
      },
      formData: {
        class: 'game_purchase',
        comment: {
          label: 'Comments',
          attribute: 'comment'
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

      if (this.gamePurchase.comment) {
        submittableData['game_purchase']['comment'] = this.gamePurchase.comment;
      }
      if (this.gamePurchase.score) {
        submittableData['game_purchase']['score'] = this.gamePurchase.score;
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
          console.log(response);
        }
      })

      this.$emit('create');
      this.$emit('closeAndRefresh');
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
