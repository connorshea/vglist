<template>
  <li>
    <a v-bind:href="gameLink">
      {{ game.name }}
    </a>
  </li>
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
      return `/games/${this.game.id}`;
    }
  }
}
</script>

