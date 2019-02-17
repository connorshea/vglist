<template>
  <div>
    <file-select
      :label="formData.cover.label"
      v-model="game.cover"
    ></file-select>

    <text-field
      :form-class="formData.class"
      :attribute="formData.name.attribute"
      :label="formData.name.label"
      v-model="game.name"
    ></text-field>

    <text-area
      :form-class="formData.class"
      :attribute="formData.description.attribute"
      :label="formData.description.label"
      v-model="game.description"
    ></text-area>

    <genre-select
      :label="formData.genres.label"
      v-model="game.genres"
    ></genre-select>

    <engine-select
      :label="formData.engines.label"
      v-model="game.engines"
    ></engine-select>

    <developer-select
      :label="formData.developers.label"
      v-model="game.developers"
    ></developer-select>

    <publisher-select
      :label="formData.publishers.label"
      v-model="game.publishers"
    ></publisher-select>

    <button
      class="button is-primary"
      value="Submit"
      @click.prevent="onSubmit"
    >Submit</button>
  </div>
</template>

<script>
import TextArea from './text-area.vue';
import TextField from './text-field.vue';
import GenreSelect from './genre-select.vue';
import EngineSelect from './engine-select.vue';
import DeveloperSelect from './developer-select.vue';
import PublisherSelect from './publisher-select.vue';
import FileSelect from './file-select.vue';
import Rails from 'rails-ujs';

export default {
  name: 'game-form',
  components: {
    TextArea,
    TextField,
    GenreSelect,
    EngineSelect,
    DeveloperSelect,
    PublisherSelect,
    FileSelect
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
    },
    engines: {
      type: Array,
      required: false,
      default: function() {
        return []
      }
    },
    developers: {
      type: Array,
      required: false,
      default: function() {
        return []
      }
    },
    publishers: {
      type: Array,
      required: false,
      default: function() {
        return []
      }
    },
    submitPath: {
      type: String,
      required: true
    },
    create: {
      type: Boolean,
      required: true
    }
  },
  data() {
    return {
      game: {
        name: this.name,
        description: this.description,
        genres: this.genres,
        engines: this.engines,
        developers: this.developers,
        publishers: this.publishers,
        cover: this.cover
      },
      formData: {
        class: 'game',
        cover: {
          label: 'Cover'
        },
        name: {
          label: 'Game title',
          attribute: 'name'
        },
        description: {
          label: 'Description',
          attribute: 'description'
        },
        genres: {
          label: 'Genres'
        },
        engines: {
          label: 'Engines'
        },
        developers: {
          label: 'Developers'
        },
        publishers: {
          label: 'Publishers'
        }
      }
    }
  },
  methods: {
    onSubmit() {
      let genre_ids = Array.from(this.game.genres, genre => genre.id);
      let engine_ids = Array.from(this.game.engines, engine => engine.id);
      let developer_ids = Array.from(this.game.developers, genre => developer.id);
      let publisher_ids = Array.from(this.game.publishers, publisher => publisher.id);
      // TODO: Add platform_ids

      let submittableData = new FormData();
      submittableData.append('game[name]', this.game.name);
      submittableData.append('game[description]', this.game.description);
      submittableData.append('game[genre_ids]', genre_ids);
      submittableData.append('game[engine_ids]', engine_ids);
      submittableData.append('game[developer_ids]', developer_ids);
      submittableData.append('game[publisher_ids]', publisher_ids);
      if (this.game.cover) {
        submittableData.append('game[cover]', this.game.cover, this.game.cover.name);
      }

      fetch(this.submitPath, {
        method: this.create ? 'POST' : 'PUT',
        body: submittableData,
        headers: {
          'X-CSRF-Token': Rails.csrfToken()
        },
        credentials: 'same-origin'
      }).then(function(response) {
        if (!response.ok) {
          throw Error(response.statusText);
        }
        return response;
      }).then(function(data) {
        Turbolinks.visit(data.url);
      }).catch(function(error) {
        console.log(error);
      });
    }
  }
}
</script>
