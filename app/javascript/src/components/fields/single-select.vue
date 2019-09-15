<template>
  <div :class="grandparentClass">
    <label v-if="label" :for="inputId" class="label">{{ label }}</label>
    <div :class="parentClass">
      <v-select
        :options="options"
        :maxHeight="maxHeight"
        :disabled="disabled"
        @search="onSearch"
        label="name"
        :inputId="inputId"
        v-bind:value="value"
        :placeholder="placeholder"
        v-on:input="$emit('input', $event)"
      ></v-select>
    </div>
  </div>
</template>

<script lang="ts">
import vSelect from 'vue-select';
import 'vue-select/dist/vue-select.css';
import * as _ from 'lodash';

export default {
  name: 'single-select',
  components: {
    vSelect
  },
  props: {
    label: {
      type: String,
      required: false
    },
    value: {
      type: Object,
      required: false
    },
    // TODO: Replace this with a CSS change when vue-select 3.0.0 comes out.
    // https://github.com/sagalbot/vue-select/pull/759
    maxHeight: {
      type: String,
      required: false,
      default: '400px'
    },
    disabled: {
      type: Boolean,
      required: false,
      default: false
    },
    searchPathIdentifier: {
      type: String,
      required: true
    },
    grandparentClass: {
      type: String,
      required: false,
      default: 'field'
    },
    parentClass: {
      type: String,
      required: false,
      default: 'control'
    },
    placeholder: {
      type: String,
      required: false
    }
  },
  data: function() {
    return {
      options: [],
      searchPath: `${window.location.origin}/${this.searchPathIdentifier}/search.json`
    };
  },
  methods: {
    /*
     * @param {search}  String   Current search text
     * @param {loading} Function Toggle loading class
     */
    onSearch: _.debounce(function(search, loading) {
      loading(true);
      let searchUrl = new URL(this.searchPath);
      searchUrl.searchParams.append('query', search);
      // TODO: Add error handling.
      fetch(searchUrl.toString(), {
        headers: {
          'Content-Type': 'application/json'
        }
      })
        .then(response => {
          return response.json();
        })
        .then(items => {
          this.options = items;
          loading(false);
        });
    }, 250)
  },
  computed: {
    inputId() {
      return _.snakeCase(this.label);
    }
  }
};
</script>
