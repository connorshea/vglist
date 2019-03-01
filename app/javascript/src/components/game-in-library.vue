<template>
  <a v-bind:href="gameLink">
    <div class="columns game-library-row">
      <div class="column game-name">{{ game.name }}</div>
      <div class="column game-score">{{ game.score }}</div>
      <div class="column game-comment">{{ game.comment }}</div>
    </div>
  </a>
</template>

<script>
export default {
  name: 'game-in-library',
  props: {
    game: {
      type: Object,
      required: true
    }
  },
  computed: {
    gameLink() {
      return `/games/${this.game.game_id}`;
    }
  }
}
</script>

