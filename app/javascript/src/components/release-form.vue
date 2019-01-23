<template>
  <div>
    <text-field
      :form-class="formData.class"
      :attribute="formData.name.attribute"
      :label="formData.name.label"
      v-model="release.name"
    ></text-field>

    <text-area
      :form-class="formData.class"
      :attribute="formData.description.attribute"
      :label="formData.description.label"
      v-model="release.description"
    ></text-area>

    <game-select
      :label="formData.game.label"
      v-model="release.game"
    ></game-select>

    <platform-select
      :label="formData.platform.label"
      v-model="release.platform"
    ></platform-select>

    <developer-select
      :label="formData.developers.label"
      v-model="release.developers"
    ></developer-select>

    <publisher-select
      :label="formData.publishers.label"
      v-model="release.publishers"
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
import GameSelect from './game-select.vue';
import PlatformSelect from './platform-select.vue';
import DeveloperSelect from './developer-select.vue';
import PublisherSelect from './publisher-select.vue';
import Rails from 'rails-ujs';

export default {
  name: 'release-form',
  components: {
    TextArea,
    TextField,
    GameSelect,
    PlatformSelect,
    DeveloperSelect,
    PublisherSelect
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
    game: {
      type: Object,
      required: false,
      default: function() {
        return {}
      }
    },
    platform: {
      type: Object,
      required: false,
      default: function() {
        return {}
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
      release: {
        name: this.name,
        description: this.description,
        platform: this.platform,
        game: this.game,
        developers: this.developers,
        publishers: this.publishers
      },
      formData: {
        class: 'release',
        name: {
          label: 'Release title',
          attribute: 'name'
        },
        description: {
          label: 'Description',
          attribute: 'description'
        },
        game: {
          label: 'Game'
        },
        platform: {
          label: 'Platform'
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
      let game_id = this.release.game.id;
      let platform_id = this.release.platform.id;
      let developer_ids = Array.from(this.release.developers, developer => developer.id);
      let publisher_ids = Array.from(this.release.publishers, publisher => publisher.id);
      fetch(this.submitPath, {
        method: this.create ? 'POST' : 'PUT',
        body: JSON.stringify({ release: {
          name: this.release.name,
          description: this.release.description,
          game: game_id,
          platform: platform_id,
          developer_ids: developer_ids,
          publisher_ids: publisher_ids
        }}),
        headers: {
          'Content-Type': 'application/json',
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
