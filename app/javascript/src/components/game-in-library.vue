<template>
  <div class="columns game-library-row">
    <div class="column game-name">
      <a v-bind:href="gameInLibrary.game_url">
        {{ gameInLibrary.game.name }}
      </a>
    </div>
    <div class="column game-score">{{ gameInLibrary.score }}</div>
    <div class="column game-comments">{{ gameInLibrary.comments }}</div>
    <div v-if="isEditable" class="column game-actions">
      <a @click="onEdit">Edit</a>
      <a @click="onDelete">Remove</a>
    </div>
  </div>
</template>

<script>
import Rails from 'rails-ujs';

export default {
  name: 'game-in-library',
  props: {
    gameInLibrary: {
      type: Object,
      required: true
    },
    isEditable: {
      type: Boolean,
      required: true
    }
  },
  methods: {
    onEdit() {
      this.$emit('edit', this.gameInLibrary);
    },
    onDelete() {
      if (window.confirm(`Remove ${this.gameInLibrary.game.name} from your library?`)) {
        // Post a delete request to the game purchase endpoint to delete the game.
        fetch(this.gameInLibrary.url, {
          method: 'DELETE',
          headers: {
            'X-CSRF-Token': Rails.csrfToken(),
            'Accept': 'application/json'
          },
          credentials: 'same-origin'
        }).then((response) => {
          if (response.ok) {
            // Emit a delete event to force the parent library component to
            // refresh.
            this.$emit('delete');
          }
        })
      }
    }
  }
}
</script>

