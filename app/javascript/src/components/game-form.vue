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

    <file-select :label="formData.cover.label" v-model="game.cover" @update:modelValue="onChange"></file-select>

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
      :label="formData.steamAppIds.label"
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

<script setup lang="ts">
import { ref } from 'vue';
import type { Option } from 'vue3-select-component';
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


// Helper to convert { id, name } to { value, label } for vue3-select-component
function toOption(item: { id: number; name: string }): Option<number> {
  return { value: item.id, label: item.name };
}

// Helper to convert array of { id, name } to Option[]
function toOptions(items: Array<{ id: number; name: string }>): Option<number>[] {
  return items.map(toOption);
}

interface Props {
  name?: string;
  releaseDate?: Date;
  genres?: Array<{ id: number; name: string }>;
  engines?: Array<{ id: number; name: string }>;
  developers?: Array<{ id: number; name: string }>;
  publishers?: Array<{ id: number; name: string }>;
  platforms?: Array<{ id: number; name: string }>;
  series?: { id: number; name: string } | null;
  steamAppIds?: Array<{ id?: number; app_id: string }>;
  epicGamesStoreId?: string;
  gogId?: string;
  igdbId?: string;
  wikidataId?: number;
  pcgamingwikiId?: string;
  mobygamesId?: number;
  giantbombId?: string;
  submitPath: string;
  railsDirectUploadsPath: string;
  successPath?: string;
  cancelPath: string;
  create: boolean;
  cover?: File;
  coverBlob?: string;
}

const props = withDefaults(defineProps<Props>(), {
  name: '',
  genres: () => [],
  engines: () => [],
  developers: () => [],
  publishers: () => [],
  platforms: () => [],
  steamAppIds: () => []
});

const errors = ref<string[]>([]);

// Convert incoming { id, name } data to { value, label } format for vue3-select-component
const game = ref({
  name: props.name,
  releaseDate: props.releaseDate ? props.releaseDate.toString() : undefined,
  genres: toOptions(props.genres),
  engines: toOptions(props.engines),
  developers: toOptions(props.developers),
  publishers: toOptions(props.publishers),
  platforms: toOptions(props.platforms),
  series: props.series ? toOption(props.series) : null,
  steamAppIds: props.steamAppIds.map(s => ({ value: s.app_id, label: s.app_id })) as Option<string>[],
  epicGamesStoreId: props.epicGamesStoreId,
  gogId: props.gogId,
  igdbId: props.igdbId,
  wikidataId: props.wikidataId?.toString(),
  pcgamingwikiId: props.pcgamingwikiId,
  mobygamesId: props.mobygamesId?.toString(),
  giantbombId: props.giantbombId,
  cover: props.cover,
  coverBlob: props.coverBlob
});

const formData = {
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
};

function onChange(file: File) {
  uploadFile(file);
}

function uploadFile(file: File) {
  const url = props.railsDirectUploadsPath;
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
    } else if (blob) {
      game.value.coverBlob = blob.signed_id;
    }
  });
}

function onSubmit() {
  // Extract IDs from Option<number> format (value property contains the ID)
  const genreIds = game.value.genres.map(g => g.value);
  const engineIds = game.value.engines.map(e => e.value);
  const developerIds = game.value.developers.map(d => d.value);
  const publisherIds = game.value.publishers.map(p => p.value);
  const platformIds = game.value.platforms.map(p => p.value);

  // Handle Steam App IDs - compare current vs original to detect deletions
  const steamAppIds: Array<{ id?: number; app_id: string; _destroy?: boolean }> = [];
  const currentAppIds = game.value.steamAppIds.map(s => s.value);

  // Add current steam app IDs
  game.value.steamAppIds.forEach((option) => {
    const originalRecord = props.steamAppIds.find(s => s.app_id === option.value);
    if (originalRecord?.id !== undefined) {
      steamAppIds.push({ id: originalRecord.id, app_id: option.value });
    } else {
      steamAppIds.push({ app_id: option.value });
    }
  });

  // Mark removed steam app IDs for destruction
  props.steamAppIds.forEach((original) => {
    if (!currentAppIds.includes(original.app_id) && original.id !== undefined) {
      steamAppIds.push({ id: original.id, app_id: original.app_id, _destroy: true });
    }
  });

  const submittableData: Record<string, any> = {
    game: {
      name: game.value.name,
      release_date: game.value.releaseDate,
      genre_ids: genreIds,
      engine_ids: engineIds,
      developer_ids: developerIds,
      publisher_ids: publisherIds,
      platform_ids: platformIds,
      steam_app_ids_attributes: steamAppIds,
      epic_games_store_id: game.value.epicGamesStoreId,
      gog_id: game.value.gogId,
      igdb_id: game.value.igdbId,
      wikidata_id: game.value.wikidataId,
      pcgamingwiki_id: game.value.pcgamingwikiId,
      mobygames_id: game.value.mobygamesId,
      giantbomb_id: game.value.giantbombId
    }
  };

  // If the attribute's value is an empty string, replace it with null so
  // it's nullified when sent to the backend.
  ['epic_games_store_id', 'gog_id', 'igdb_id', 'wikidata_id', 'pcgamingwiki_id', 'mobygames_id', 'giantbomb_id'].forEach(attr => {
    if (submittableData.game[attr] === '') {
      submittableData.game[attr] = null;
    }
  });

  // Extract series ID from Option format (value property contains the ID)
  if (game.value.series) {
    submittableData.game.series_id = game.value.series.value;
  } else {
    submittableData.game.series_id = null;
  }

  if (game.value.coverBlob) {
    submittableData.game.cover = game.value.coverBlob;
  }

  VglistUtils.authenticatedFetch(
    props.submitPath,
    props.create ? 'POST' : 'PUT',
    JSON.stringify(submittableData)
  ).then((gameResponse: any) => {
      if (props.create) {
        Turbolinks.visit(`${window.location.origin}/games/${gameResponse.id}`);
      } else {
        Turbolinks.visit(props.successPath || '/');
      }
    })
    .catch(errorsResp => {
      errors.value = errorsResp;
      const submitButton = document.querySelector('.js-submit-button');
      if (submitButton) {
        submitButton.classList.add('js-submit-button-error');
        setTimeout(() => {
          submitButton.classList.remove('js-submit-button-error');
        }, 2000);
      }
    });
}
</script>
