<template>
  <div class="columns game-library-row">
    <div class="column game-name">
      <a v-bind:href="gameInLibrary.game_url">
        {{ gameInLibrary.game.name }}
      </a>
    </div>
    <div class="column game-rating">{{ gameInLibrary.rating }}</div>
    <div class="column game-hours-played">
      {{ formattedHoursPlayed }}
    </div>
    <div class="column game-completion-status">
      {{ gameInLibrary.completion_status.label }}
    </div>
    <div class="column game-start-and-completion-dates">
      {{ formattedStartAndCompletionDates }}
    </div>
    <div class="column game-start-and-completion-dates">
      <p v-for="platform in gameInLibrary.platforms" :key="platform.id">
        {{ platform.name }}
      </p>
    </div>
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
  },
  computed: {
    // 
    // Return values depend on which values are available, they should match what the backend sends.
    // No start or completion date: ''
    // Completion date but no start date: '??? – March 20, 2019'
    // Start date but no completion date: 'March 10, 2019 – ???'
    // Start and completion date: 'March 10, 2019 – March 20, 2019'
    formattedStartAndCompletionDates: function() {
      let options = { timeZone: 'UTC', year: 'numeric', month: 'long', day: 'numeric' };
      let returnString = '';
      let startDateString = this.gameInLibrary.start_date;
      let completionDateString = this.gameInLibrary.completion_date;

      if (startDateString !== null && completionDateString !== null) {
        let startDate = new Date(startDateString);
        let completionDate = new Date(completionDateString);
        returnString = `${startDate.toLocaleDateString('en-US', options)} – ${completionDate.toLocaleDateString('en-US', options)}`;
      } else if (startDateString !== null) {
        let startDate = new Date(startDateString);
        returnString = `${startDate.toLocaleDateString('en-US', options)} – ???`;
      } else if (completionDateString !== null) {
        let completionDate = new Date(completionDateString);
        returnString = `??? – ${completionDate.toLocaleDateString('en-US', options)}`;
      }

      return returnString;
    },
    formattedHoursPlayed: function() {
      let hoursPlayed = this.gameInLibrary.hours_played;

      // Return nothing if hoursPlayed is null.
      if (hoursPlayed === null) { return; }

      // Return "x hours" for time played.
      return `${Math.floor(hoursPlayed)} hours`;
    }
  }
}
</script>

