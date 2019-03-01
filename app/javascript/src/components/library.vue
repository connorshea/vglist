<template>
  <div class="game-library">
    <div v-if="purchasedGames.length > 0" class="columns game-library-header game-library-row">
      <div class="column game-name">Game</div>
      <div class="column game-score">Score</div>
      <div class="column game-comment">Comment</div>
    </div>
    <game-in-library
      v-for="gameInLibrary in purchasedGames"
      v-bind:key="gameInLibrary.id"
      v-bind:gameInLibrary="gameInLibrary"
    ></game-in-library>

    <p v-if="purchasedGames.length == 0">This library is empty.</p>
  </div>
</template>

<script>
import GameInLibrary from './game-in-library.vue';

export default {
  components: {
    GameInLibrary
  },
  props: {
    gamePurchasesUrl: {
      type: String,
      required: true
    }
  },
  data: function() {
    return {
      purchasedGames: []
    }
  },
  created: function() {
    fetch(this.gamePurchasesUrl, {
      headers: {
        "Content-Type": "application/json"
      }
    }).then((response) => {
      return response.json().then((json) => {
        if (response.ok) {
          return Promise.resolve(json);
        }
        return Promise.reject(json);
      });
    }).then((purchasedGames) => {
      this.purchasedGames = purchasedGames;
    });
  }
}
</script>

