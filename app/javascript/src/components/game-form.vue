<template>
  <div id="game-form">
    <!-- Display errors if there are any. -->
    <div class="notification errors-notification is-danger" v-if="errors.length > 0">
      <p>
        {{ errors.length > 1 ? 'Errors' : 'An error' }} prevented this game from
        being saved:
      </p>
      <ul>
        <li v-for="error in errors" :key="error">{{ error }}</li>
      </ul>
    </div>

    <file-select :label="formData.cover.label" v-model="game.cover" @input="onChange"></file-select>

    <text-field
      :form-class="formData.class"
      :attribute="formData.name.attribute"
      :label="formData.name.label"
      :required="true"
      v-model="game.name"
    ></text-field>

    <date-field
      :form-class="formData.class"
      :attribute="formData.releaseDate.attribute"
      :label="formData.releaseDate.label"
      :required="false"
      v-model="game.releaseDate"
    ></date-field>

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
      v-model="game.wikidataId"
    ></number-field>

    <multi-select-generic
      :form-class="formData.class"
      :attribute="formData.steamAppIds.attribute"
      :label="formData.steamAppIds.label"
      :v-select-label="'app_id'"
      v-model="game.steamAppIds"
    ></multi-select-generic>

    <text-field
      :form-class="formData.class"
      :attribute="formData.epicGamesStoreId.attribute"
      :label="formData.epicGamesStoreId.label"
      v-model="game.epicGamesStoreId"
    ></text-field>

    <text-field
      :form-class="formData.class"
      :attribute="formData.gogId.attribute"
      :label="formData.gogId.label"
      v-model="game.gogId"
    ></text-field>

    <text-field
      :form-class="formData.class"
      :attribute="formData.igdbId.attribute"
      :label="formData.igdbId.label"
      v-model="game.igdbId"
    ></text-field>

    <text-field
      :form-class="formData.class"
      :attribute="formData.pcgamingwikiId.attribute"
      :label="formData.pcgamingwikiId.label"
      v-model="game.pcgamingwikiId"
    ></text-field>

    <text-field
      :form-class="formData.class"
      :attribute="formData.mobygamesId.attribute"
      :label="formData.mobygamesId.label"
      v-model="game.mobygamesId"
    ></text-field>

    <text-field
      :form-class="formData.class"
      :attribute="formData.giantbombId.attribute"
      :label="formData.giantbombId.label"
      v-model="game.giantbombId"
    ></text-field>

    <button
      class="button is-primary mr-10 mr-0-mobile is-fullwidth-mobile js-submit-button"
      value="Submit"
      @click.prevent="onSubmit"
    >Submit</button>

    <a class="button is-fullwidth-mobile mt-5-mobile" :href="cancelPath">Cancel</a>
  </div>
</template>

<script lang="ts">
import TextArea from './fields/text-area.vue';
import TextField from './fields/text-field.vue';
import SingleSelect from './fields/single-select.vue';
import NumberField from './fields/number-field.vue';
import MultiSelect from './fields/multi-select.vue';
import MultiSelectGeneric from './fields/multi-select-generic.vue';
import FileSelect from './fields/file-select.vue';
import DateField from './fields/date-field.vue';
import VglistUtils from '../utils';
import { DirectUpload } from '@rails/activestorage';
import Turbolinks from 'turbolinks';
import * as _ from 'lodash';

export default {
  name: 'game-form',
  components: {
    TextArea,
    TextField,
    NumberField,
    SingleSelect,
    MultiSelect,
    MultiSelectGeneric,
    FileSelect,
    DateField
  },
  props: {
    name: {
      type: String,
      required: false,
      default: ''
    },
    releaseDate: {
      type: Date,
      required: false
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
    steamAppIds: {
      type: Array,
      required: false,
      default: function() {
        return [];
      }
    },
    epicGamesStoreId: {
      type: String,
      required: false
    },
    gogId: {
      type: String,
      required: false
    },
    igdbId: {
      type: String,
      required: false
    },
    wikidataId: {
      type: Number,
      required: false
    },
    pcgamingwikiId: {
      type: String,
      required: false
    },
    mobygamesId: {
      type: String,
      required: false
    },
    giantbombId: {
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
        name: this.$props.name,
        releaseDate: this.$props.releaseDate,
        genres: this.$props.genres,
        engines: this.$props.engines,
        developers: this.$props.developers,
        publishers: this.$props.publishers,
        platforms: this.$props.platforms,
        series: this.$props.series,
        steamAppIds: this.$props.steamAppIds,
        epicGamesStoreId: this.$props.epicGamesStoreId,
        gogId: this.$props.gogId,
        igdbId: this.$props.igdbId,
        wikidataId: this.$props.wikidataId,
        pcgamingwikiId: this.$props.pcgamingwikiId,
        mobygamesId: this.$props.mobygamesId,
        giantbombId: this.$props.giantbombId,
        cover: this.$props.cover,
        coverBlob: this.$props.coverBlob
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
        releaseDate: {
          label: 'Release Date',
          attribute: 'release_date'
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
        steamAppIds: {
          label: 'Steam Application IDs',
          attribute: 'steam_app_ids'
        },
        epicGamesStoreId: {
          label: 'Epic Games Store ID',
          attribute: 'epic_games_store_id'
        },
        gogId: {
          label: 'GOG.com ID',
          attribute: 'gog_id'
        },
        igdbId: {
          label: 'IGDB ID',
          attribute: 'igdb_id'
        },
        wikidataId: {
          label: 'Wikidata ID',
          attribute: 'wikidata_id'
        },
        pcgamingwikiId: {
          label: 'PCGamingWiki ID',
          attribute: 'pcgamingwiki_id'
        },
        mobygamesId: {
          label: 'MobyGames ID',
          attribute: 'mobygames_id'
        },
        giantbombId: {
          label: 'Giant Bomb ID',
          attribute: 'giantbomb_id'
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
      const upload = new DirectUpload(file, url, {
        directUploadWillStoreFileWithXHR: (xhr) => {
          // Use this workaround to make sure that Direct Upload-ed images are
          // uploaded with the correct header. Otherwise they will end up being
          // private files.
          xhr.setRequestHeader('x-amz-acl', 'public-read');
        }
      });

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
      let genreIds = Array.from(
        this.game.genres,
        (genre: { id: String }) => genre.id
      );
      let engineIds = Array.from(
        this.game.engines,
        (engine: { id: String }) => engine.id
      );
      let developerIds = Array.from(
        this.game.developers,
        (developer: { id: String }) => developer.id
      );
      let publisherIds = Array.from(
        this.game.publishers,
        (publisher: { id: String }) => publisher.id
      );
      let platformIds = Array.from(
        this.game.platforms,
        (platform: { id: String }) => platform.id
      );

      let steamAppIds = [];
      let difference = _.difference(
        this.$props.steamAppIds,
        this.game.steamAppIds
      );
      // These can be either the steamAppId itself or the full record with ID and everything.
      // If its just been added to the select, it's an integer.
      this.game.steamAppIds.forEach((steamAppIdRecordOrInteger) => {
        if (steamAppIdRecordOrInteger.id !== undefined) {
          steamAppIds.push({ id: steamAppIdRecordOrInteger.id, app_id: steamAppIdRecordOrInteger.app_id });
        } else {
          steamAppIds.push({ app_id: steamAppIdRecordOrInteger });
        }
      });
      difference.forEach((appId: any) => {
        steamAppIds.push({ id: appId.id, app_id: appId.app_id, _destroy: true });
      });

      let submittableData = {
        game: {
          name: this.game.name,
          release_date: this.game.releaseDate,
          genre_ids: genreIds,
          engine_ids: engineIds,
          developer_ids: developerIds,
          publisher_ids: publisherIds,
          platform_ids: platformIds,
          steam_app_ids_attributes: steamAppIds,
          epic_games_store_id: this.game.epicGamesStoreId,
          gog_id: this.game.gogId,
          igdb_id: this.game.igdbId,
          wikidata_id: this.game.wikidataId,
          pcgamingwiki_id: this.game.pcgamingwikiId,
          mobygames_id: this.game.mobygamesId,
          giantbomb_id: this.game.giantbombId
        }
      };

      // If the attribute's value is an empty string, replace it with null so
      // it's nullified when sent to the backend.
      ['epic_games_store_id', 'gog_id', 'igdb_id', 'wikidata_id', 'pcgamingwiki_id', 'mobygames_id', 'giantbomb_id'].forEach(attr => {
        if (submittableData['game'][attr] === '') {
          submittableData['game'][attr] = null;
        }
      });

      if (this.game.series) {
        submittableData['game']['series_id'] = this.game.series.id;
      } else {
        submittableData['game']['series_id'] = null;
      }

      if (this.game.coverBlob) {
        submittableData['game']['cover'] = this.game.coverBlob;
      }

      VglistUtils.authenticatedFetch(
        this.submitPath,
        this.create ? 'POST' : 'PUT',
        JSON.stringify(submittableData)
      ).then(game => {
          if (this.create) {
            Turbolinks.visit(`${window.location.origin}/games/${game.id}`);
          } else {
            Turbolinks.visit(this.successPath);
          }
        })
        .catch(errors => {
          this.errors = errors;
          let submitButton = document.querySelector('.js-submit-button');
          submitButton.classList.add('js-submit-button-error');
          setTimeout(() => {
            submitButton.classList.remove('js-submit-button-error');
          }, 2000);
        });
    }
  }
};
</script>
