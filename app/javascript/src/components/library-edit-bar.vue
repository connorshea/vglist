<template>
  <div class="library-edit-bar level">
    <div class="level-left">
      <span class="has-text-weight-bold pr-15">{{ selectedGamesString }}</span>
      <number-field
        :form-class="''"
        :field-class="'mb-0 mr-5'"
        :attribute="'rating'"
        :placeholder="'Rating (out of 100)'"
        :required="false"
        :max="100"
        v-model="updateData.rating"
      ></number-field>
      <static-single-select
        :placeholder="'Completion Status'"
        :grandparent-class="'field mb-0 mr-5'"
        v-model="updateData.completion_status"
        :options="formattedCompletionStatuses"
      ></static-single-select>
      <multi-select
        :placeholder="'Stores'"
        v-model="updateData.stores"
        :search-path-identifier="'stores'"
      ></multi-select>
    </div>
    <div class="level-right">
      <button
        class="button is-fullwidth-mobile mr-5 mr-0-mobile"
        @click="$emit('closeEditBar')"
      >Cancel</button>
      <button
        class="button is-fullwidth-mobile is-primary mr-5 mr-0-mobile"
        :disabled="!updateButtonActive"
        @click="updateGames"
      >Update</button>
    </div>
  </div>
</template>

<script lang="ts">
import VglistUtils from '../utils';
import Turbolinks from 'turbolinks';
import NumberField from './fields/number-field.vue';
import StaticSingleSelect from './fields/static-single-select.vue';
import MultiSelect from './fields/multi-select.vue';

export default {
  name: 'library-edit-bar',
  components: {
    NumberField,
    StaticSingleSelect,
    MultiSelect
  },
  props: {
    gamePurchases: {
      type: Array,
      required: true
    }
  },
  data: function() {
    return {
      updateData: {
        ids: [],
        completion_status: null,
        rating: null,
        stores: []
      },
      completionStatuses: {
        unplayed: 'Unplayed',
        in_progress: 'In Progress',
        paused: 'Paused',
        dropped: 'Dropped',
        completed: 'Completed',
        fully_completed: '100% Completed',
        not_applicable: 'N/A'
      }
    };
  },
  methods: {
    updateGames(): void {
      // Clear the array first.
      this.updateData['ids'] = [];
      this.gamePurchases.forEach(gamePurchase => {
        this.updateData['ids'].push(gamePurchase.id);
      });

      if (this.updateData['rating'] === null) {
        delete this.updateData['rating'];
      }

      if (this.updateData['stores'].length !== 0) {
        delete this.updateData['stores'];
      }

      // Clone the object before we mess with the values.
      // This prevents the values in the edit bar from changing when these
      // values are changed.
      let updateData = this.updateData;

      if (updateData['completion_status'] !== null) {
        updateData['completion_status'] = updateData['completion_status']['value'];
      }

      if (updateData['stores'].length !== 0) {
        updateData['store_ids'] = updateData['stores'].map(store => store.id);
        delete updateData['stores'];
      }

      VglistUtils.rawAuthenticatedFetch(
        '/game_purchases/bulk_update.json',
        'POST',
        JSON.stringify(updateData)
      ).then(response => {
        if (response.ok) {
          // Redirects to self.
          Turbolinks.visit(window.location.href);
        } else {
          console.log('Add error handling, doofus.');
        }
      });
    }
  },
  computed: {
    selectedGamesString(): string {
      let gpLength = this.gamePurchases.length;
      return `${gpLength} game${gpLength > 1 ? 's' : ''} selected`;
    },
    updateButtonActive(): boolean {
      if (Object.keys(this.updateData).length === 1) {
        return false;
      }

      let returnBool = false;

      // Check if rating, completion status, or stores have values.
      // If they do, return true. Otherwise, return false.
      ['rating', 'completion_status', 'stores'].forEach(attribute => {
        if (
          typeof this.updateData[attribute] !== 'undefined' &&
          this.updateData[attribute] !== '' &&
          this.updateData[attribute] !== null &&
          this.updateData[attribute].length !== 0
        ) {
          returnBool = true;
        }
      });

      return returnBool;
    },
    formattedCompletionStatuses(): any {
      return Object.entries(this.completionStatuses).map(status => {
        return { label: status[1], value: status[0] };
      });
    }
  }
};
</script>
