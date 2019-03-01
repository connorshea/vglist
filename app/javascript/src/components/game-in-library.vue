<template>
  <a v-bind:href="gameLink">
    <div class="columns game-library-row">
      <div class="column game-name">{{ gameInLibrary.game.name }}</div>
      <div class="column game-score">{{ gameInLibrary.score }}</div>
      <div class="column game-comment">{{ gameInLibrary.comment }}</div>
    </div>
  </a>
</template>

<script>
export default {
  name: 'game-in-library',
  props: {
    gameInLibrary: {
      type: Object,
      required: true
    }
  },
  computed: {
    gameLink() {
      return `/games/${this.gameInLibrary.game.id}`;
    }
  }
}
</script>

