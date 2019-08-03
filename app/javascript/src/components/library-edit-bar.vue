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
      test: null
    };
  },
  methods: {
    updateGames() {
      console.log('foo');
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
