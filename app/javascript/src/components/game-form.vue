<template>
  <div>
    <!-- Display errors if there are any. -->
    <div class="notification errors-notification is-danger" v-if="errors.length > 0">
      <p>{{ errors.length > 1 ? 'Errors' : 'An error'}} prevented this game from being saved:</p>
      <ul>
        <li v-for="error in errors" :key="error">
          {{ error }}
        </li>
      </ul>
    </div>

    <file-select
      :label="formData.cover.label"
      v-model="game.cover"
      @input="onChange"
    ></file-select>

    <text-field
      :form-class="formData.class"
      :attribute="formData.name.attribute"
      :label="formData.name.label"
      :required="true"
      v-model="game.name"
    ></text-field>

    <text-area
      :form-class="formData.class"
      :attribute="formData.description.attribute"
      :label="formData.description.label"
      v-model="game.description"
    ></text-area>

    <multi-select
      :label="formData.genres.label"
      v-model="game.genres"
      :search-path-identifier="'genres'"
    ></multi-select>

    <multi-select
      :label="formData.engines.label"
      v-model="game.engines"
      :search-path-identifier="'engines'"
    ></multi-select>

    <multi-select
      :label="formData.developers.label"
      v-model="game.developers"
      :search-path-identifier="'companies'"
    ></multi-select>
    
    <multi-select
      :label="formData.publishers.label"
      v-model="game.publishers"
      :search-path-identifier="'companies'"
    ></multi-select>

    <multi-select
      :label="formData.platforms.label"
      v-model="game.platforms"
      :search-path-identifier="'platforms'"
    ></multi-select>

    <button
      class="button is-primary"
      value="Submit"
      @click.prevent="onSubmit"
    >Submit</button>

    <a
      class="button"
      :href="cancelPath"
    >Cancel</a>
  </div>
</template>

<script>
import TextArea from './text-area.vue';
import TextField from './text-field.vue';
import MultiSelect from './multi-select.vue';
import FileSelect from './file-select.vue';
import Rails from 'rails-ujs';
import { DirectUpload } from 'activestorage';

export default {
  name: 'game-form',
  components: {
    TextArea,
    TextField,
    MultiSelect,
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
    platforms: {
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
    railsDirectUploadsPath: {
      type: String,
      required: true
    },
    successPath: {
      type: String,
      required: false
    },
    cancelPath: {
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
      errors: [],
      game: {
        name: this.name,
        description: this.description,
        genres: this.genres,
        engines: this.engines,
        developers: this.developers,
        publishers: this.publishers,
        platforms: this.platforms,
        cover: this.cover,
        coverBlob: this.coverBlob
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
        },
        platforms: {
          label: 'Platforms'
        }
      }
    }
  },
  methods: {
    onChange(file) {
      this.uploadFile(file);
    },
    uploadFile(file) {
      const url = this.railsDirectUploadsPath;
      const upload = new DirectUpload(file, url);

      upload.create((error, blob) => {
        if (error) {
          // TODO: Handle this error.
          console.log(error);
        } else {
          this.game.coverBlob = blob.signed_id;
        }
      })
    },
    onSubmit() {
      let genre_ids = Array.from(this.game.genres, genre => genre.id);
      let engine_ids = Array.from(this.game.engines, engine => engine.id);
      let developer_ids = Array.from(this.game.developers, developer => developer.id);
      let publisher_ids = Array.from(this.game.publishers, publisher => publisher.id);
      let platform_ids = Array.from(this.game.platforms, platform => platform.id);

      let submittableData = { game: {
        name: this.game.name,
        description: this.game.description,
        genre_ids: genre_ids,
        engine_ids: engine_ids,
        developer_ids: developer_ids,
        publisher_ids: publisher_ids,
        platform_ids: platform_ids
      }};

      if (this.game.coverBlob) {
        submittableData['game']['cover'] = this.game.coverBlob;
      }

      fetch(this.submitPath, {
        method: this.create ? 'POST' : 'PUT',
        body: JSON.stringify(submittableData),
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': Rails.csrfToken(),
          'Accept': 'application/json'
        },
        credentials: 'same-origin'
      }).then((response) => {
        // https://stackoverflow.com/questions/50041257/how-can-i-pass-json-body-of-fetch-response-to-throw-error-with-then
        return response.json().then((json) => {
          if (response.ok) {
            return Promise.resolve(json);
          }
          return Promise.reject(json);
        });
      }).then((game) => {
        if (this.create) {
          Turbolinks.visit(`${window.location.origin}/games/${game.id}`);
        } else {
          Turbolinks.visit(this.successPath);
        }
      }).catch((errors) => {
        this.errors = errors;
      });
    }
  }
}
</script>
