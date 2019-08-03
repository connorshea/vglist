<template>
  <div class="library-edit-bar">
    <p class="has-text-weight-bold">{{ gamePurchases.length }} games selected</p>

    <!-- <ul v-for="gamePurchase in gamePurchases" :key="gamePurchase.id">
      <li>{{gamePurchase}}</li>
    </ul>-->
    <button class="button is-fullwidth-mobile mr-5 mr-0-mobile" @click="updateGames">Update</button>
    <button class="button is-fullwidth-mobile mr-5 mr-0-mobile" @click="$emit('closeEditBar')">Close</button>
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
  }
};
</script>
