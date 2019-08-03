<template>
  <div class="library-edit-bar level">
    <div class="level-left">
      <span class="has-text-weight-bold">{{ selectedGamesString }}</span>
    </div>
    <div class="level-right">
      <button
        class="button is-fullwidth-mobile mr-5 mr-0-mobile"
        @click="$emit('closeEditBar')"
      >Cancel</button>
      <button class="button is-fullwidth-mobile mr-5 mr-0-mobile" @click="updateGames">Update</button>
    </div>
  </div>
</template>

<script lang="ts">
import Rails from 'rails-ujs';
import Turbolinks from 'turbolinks';
import SingleSelect from './fields/single-select.vue';

export default {
  name: 'library-edit-bar',
  components: {
    SingleSelect
  },
  props: {
    gamePurchases: {
      type: Array,
      required: true
    }
  },
  data: function() {
    return {
      updateData: {
        game_purchase_ids: [],
        rating: 100
      }
    };
  },
  methods: {
    updateGames() {
      console.log(this.gamePurchases);
      this.gamePurchases.forEach(gamePurchase => {
        this.updateData['game_purchase_ids'].push(gamePurchase.id);
      });

      console.log(this.updateData);

      fetch('/game_purchases/bulk_update.json', {
        method: 'POST',
        body: JSON.stringify(this.updateData),
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': Rails.csrfToken(),
          Accept: 'application/json'
        },
        credentials: 'same-origin'
      }).then(response => {
        if (response.ok) {
          // Redirects to self.
          Turbolinks.visit(window.location);
        } else {
          console.log('Add error handling, doofus.');
        }
      });
    }
  },
  computed: {
    selectedGamesString() {
      let gpLength = this.gamePurchases.length;
      return `${gpLength} game${gpLength > 1 ? 's' : ''} selected`;
    }
  }
};
</script>
