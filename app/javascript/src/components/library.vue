<template>
  <ul>
    <game-in-library
      v-for="game in purchasedGames"
      v-bind:key="game.id"
      v-bind:game="game"
    ></game-in-library>
  </ul>
</template>

<script>
import GameInLibrary from './game-in-library.vue';

export default {
  components: {
    GameInLibrary
  },
  props: {
    purchasedGames: {
      type: Array,
      required: true
    }
  }
}
</script>

