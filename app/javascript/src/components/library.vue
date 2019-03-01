<template>
  <div class="game-library">
    <div class="columns game-library-header game-library-row">
      <div class="column game-name">Game</div>
      <div class="column game-score">Score</div>
      <div class="column game-comment">Comment</div>
    </div>
    <game-in-library
      v-for="game in purchasedGames"
      v-bind:key="game.id"
      v-bind:game="game"
    ></game-in-library>
  </div>
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

