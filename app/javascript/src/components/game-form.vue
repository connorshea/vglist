<template>
  <div>
    <!-- Display errors if there are any. -->
    <div
      class="notification errors-notification is-danger"
      v-if="errors.length > 0"
    >
      <p>
        {{ errors.length > 1 ? 'Errors' : 'An error' }} prevented this game from
        being saved:
      </p>
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

    <single-select
      :label="formData.series.label"
      v-model="game.series"
      :search-path-identifier="'series'"
    ></single-select>

    <number-field
      :form-class="formData.class"
      :attribute="formData.wikidataId.attribute"
      :label="formData.wikidataId.label"
      v-model="game.wikidata_id"
    ></number-field>

    <number-field
      :form-class="formData.class"
      :attribute="formData.steamAppId.attribute"
      :label="formData.steamAppId.label"
      v-model="game.steam_app_id"
    ></number-field>

    <text-field
      :form-class="formData.class"
      :attribute="formData.pcgamingwikiId.attribute"
      :label="formData.pcgamingwikiId.label"
      v-model="game.pcgamingwiki_id"
    ></text-field>

    <button class="button is-primary" value="Submit" @click.prevent="onSubmit">
      Submit
    </button>

    <a class="button" :href="cancelPath">Cancel</a>
  </div>
</template>

<script>
import TextArea from './fields/text-area.vue';
import TextField from './fields/text-field.vue';
import SingleSelect from './fields/single-select.vue';
import NumberField from './fields/number-field';
import MultiSelect from './fields/multi-select.vue';
import FileSelect from './fields/file-select.vue';
import Rails from 'rails-ujs';
import { DirectUpload } from 'activestorage';

export default {
  name: 'game-form',
  components: {
    TextArea,
    TextField,
    NumberField,
    SingleSelect,
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
        return [];
      }
    },
    engines: {
      type: Array,
      required: false,
      default: function() {
        return [];
      }
    },
    developers: {
      type: Array,
      required: false,
      default: function() {
        return [];
      }
    },
    publishers: {
      type: Array,
      required: false,
      default: function() {
        return [];
      }
    },
    platforms: {
      type: Array,
      required: false,
      default: function() {
        return [];
      }
    },
    series: {
      type: Object,
      required: false,
      default: function() {
        return { name: '' };
      }
    },
    steam_app_id: {
      type: Number,
      required: false
    },
    wikidata_id: {
      type: Number,
      required: false
    },
    pcgamingwiki_id: {
      type: String,
      required: false
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
        series: this.series,
        steam_app_id: this.steam_app_id,
        wikidata_id: this.wikidata_id,
        pcgamingwiki_id: this.pcgamingwiki_id,
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
        },
        series: {
          label: 'Series'
        },
        steamAppId: {
          label: 'Steam Application ID',
          attribute: 'steam_app_id'
        },
        wikidataId: {
          label: 'Wikidata ID',
          attribute: 'wikidata_id'
        },
        pcgamingwikiId: {
          label: 'PCGamingWiki ID',
          attribute: 'pcgamingwiki_id'
        }
      }
    };
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
      });
    },
    onSubmit() {
      let genre_ids = Array.from(this.game.genres, genre => genre.id);
      let engine_ids = Array.from(this.game.engines, engine => engine.id);
      let developer_ids = Array.from(
        this.game.developers,
        developer => developer.id
      );
      let publisher_ids = Array.from(
        this.game.publishers,
        publisher => publisher.id
      );
      let platform_ids = Array.from(
        this.game.platforms,
        platform => platform.id
      );

      let submittableData = {
        game: {
          name: this.game.name,
          description: this.game.description,
          genre_ids: genre_ids,
          engine_ids: engine_ids,
          developer_ids: developer_ids,
          publisher_ids: publisher_ids,
          platform_ids: platform_ids,
          steam_app_id: this.game.steam_app_id,
          wikidata_id: this.game.wikidata_id,
          pcgamingwiki_id: this.game.pcgamingwiki_id
        }
      };

      if (this.game.series) {
        submittableData['game']['series_id'] = this.game.series.id;
      }

      if (this.game.coverBlob) {
        submittableData['game']['cover'] = this.game.coverBlob;
      }

      fetch(this.submitPath, {
        method: this.create ? 'POST' : 'PUT',
        body: JSON.stringify(submittableData),
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': Rails.csrfToken(),
          Accept: 'application/json'
        },
        credentials: 'same-origin'
      })
        .then(response => {
          // https://stackoverflow.com/questions/50041257/how-can-i-pass-json-body-of-fetch-response-to-throw-error-with-then
          return response.json().then(json => {
            if (response.ok) {
              return Promise.resolve(json);
            }
            return Promise.reject(json);
          });
        })
        .then(game => {
          if (this.create) {
            Turbolinks.visit(`${window.location.origin}/games/${game.id}`);
          } else {
            Turbolinks.visit(this.successPath);
          }
        })
        .catch(errors => {
          this.errors = errors;
        });
    }
  }
};
</script>
