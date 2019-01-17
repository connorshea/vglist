<template>
  <div>
    <text-field
      :form-class='"game"'
      :attribute='"name"'
      :label='"Game title"'
      v-model="game.name"
    ></text-field>

    <text-area
      :form-class='"game"'
      :attribute='"description"'
      :label='"Description"'
      v-model="game.description"
    ></text-area>

    <genre-select
      :genres-path="genresPath"
      :label='"Genres"'
      v-model="game.genres"
    ></genre-select>

    <input
      class="button is-primary"
      type="submit"
      value="Submit"
      @click.prevent="onSubmit"
    >
  </div>
</template>

<script>
import TextArea from './text-area.vue';
import TextField from './text-field.vue';
import GenreSelect from './genre-select.vue';
import Rails from 'rails-ujs';

export default {
  name: 'game-form',
  components: {
    TextArea, TextField, GenreSelect
  },
  props: {
    name: {
      type: String,
      required: false,
      default: ''
    },
    description: {
      type: String,
      required: false,
      default: ''
    },
    genres: {
      type: Array,
      required: false,
      default: function() {
        return []
      }
    }
  },
  data() {
    return {
      genresPath: '/genres.json',
      game: {
        name: this.name,
        description: this.description,
        genres: this.genres
      }
    }
  },
  methods: {
    onSubmit() {
      fetch('/games', {
        method: 'post',
        body: JSON.stringify(this.game),
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': Rails.csrfToken()
        },
        credentials: 'same-origin'
      }).then(function(response) {
        return response.json();
      }).then(function(data) {
        console.log(data);
      });
    }
  }
}
</script>
