<template>
  <vue-good-table
    :columns="columns"
    :rows="rows"
    :sort-options="{
        enabled: true,
        initialSortBy: { field: 'rating', type: 'desc' }
      }"
  >
    <div slot="table-actions" v-if="isEditable">
      <button v-if="isEditable" @click="addGame()" class="button mr-5">Add a game to your library</button>
    </div>
    <template slot="table-row" slot-scope="props">
      <span v-if="props.column.field == 'after'">
        <a @click="onEdit(props.row)">Edit</a>
        <a @click="onDelete(props.row)">Remove</a>
      </span>
      <span v-else-if="props.column.field == 'game.name'">
        <a :href="props.row.game_url">{{ props.row.game.name }}</a>
      </span>
      <span v-else-if="props.column.field == 'platforms'">
        <p v-for="platform in props.row.platforms" :key="platform.id">
          <a :href="`/platforms/${platform.id}`">{{ platform.name }}</a>
        </p>
      </span>
      <span v-else>{{ props.formattedRow[props.column.field] }}</span>
    </template>
    <div slot="emptystate" class="vgt-center-align">
      <span v-if="isLoading">Loading...</span>
      <span v-else class="vgt-text-disabled">This library is empty.</span>
    </div>
  </vue-good-table>
</template>

<script>
import Rails from 'rails-ujs';
import { VueGoodTable } from 'vue-good-table';
import 'vue-good-table/dist/vue-good-table.css';

export default {
  name: 'library-table',
  components: {
    VueGoodTable
  },
  props: {
    gamePurchasesUrl: {
      type: String,
      required: true
    },
    isEditable: {
      type: Boolean,
      required: true
    },
    rows: {
      type: Array,
      required: true
    },
    isLoading: {
      type: Boolean,
      required: true
    }
  },
  created: function() {
    this.loadGames();
    if (this.isEditable) {
      this.columns.push({
        label: 'Actions',
        field: 'after',
        width: '120px'
      });
    }
  },
  data: function() {
    return {
      columns: [
        {
          label: 'Name',
          field: 'game.name',
          type: 'text'
        },
        {
          label: 'Rating',
          field: 'rating',
          type: 'number'
        },
        {
          label: 'Hours Played',
          field: 'hours_played',
          type: 'decimal',
          formatFn: this.formatHoursPlayed
        },
        {
          label: 'Completion Status',
          field: 'completion_status.label',
          type: 'text'
        },
        {
          label: 'Start Date',
          field: 'start_date',
          type: 'date',
          dateInputFormat: 'YYYY-MM-DD',
          dateOutputFormat: 'MMMM D, YYYY'
        },
        {
          label: 'Completion Date',
          field: 'completion_date',
          type: 'date',
          dateInputFormat: 'YYYY-MM-DD',
          dateOutputFormat: 'MMMM D, YYYY'
        },
        {
          label: 'Platforms',
          field: 'platforms',
          type: 'text'
        },
        {
          label: 'Comments',
          field: 'comments',
          type: 'text'
        }
      ]
    };
  },
  methods: {
    onEdit(row) {
      this.$emit('edit', row);
    },
    onDelete(row) {
      if (window.confirm(`Remove ${row.game.name} from your library?`)) {
        // Post a delete request to the game purchase endpoint to delete the game.
        fetch(row.url, {
          method: 'DELETE',
          headers: {
            'X-CSRF-Token': Rails.csrfToken(),
            Accept: 'application/json'
          },
          credentials: 'same-origin'
        }).then(response => {
          if (response.ok) {
            // Emit a delete event to force the parent library component to
            // refresh.
            this.$emit('delete');
          }
        });
      }
    },
    loadGames() {
      fetch(this.gamePurchasesUrl, {
        headers: {
          'Content-Type': 'application/json'
        }
      })
        .then(response => {
          return response.json().then(json => {
            if (response.ok) {
              return Promise.resolve(json);
            }
            return Promise.reject(json);
          });
        })
        .then(purchasedGames => {
          this.games = purchasedGames;
          this.$emit('loaded');
        });
    },
    addGame() {
      this.$emit('addGame');
    },
    formatHoursPlayed(value) {
      if (value === null || parseFloat(value) === 0) {
        return;
      }

      // Split the float between the whole number and the decimals.
      let splitValue = value.split('.');
      let formattedValue = '';
      let hours = parseInt(splitValue[0]);
      // This assumes the float has only one digit after the decimal point.
      // It will break if that changes.
      let minutes = Math.floor((splitValue[1] / 10) * 60);

      // Render 1h if there are 0 minutes, 1m if there are 0 hours, or 1h1m if there are both.
      if (minutes === 0) {
        formattedValue = `${hours}h`;
      } else if (hours === 0) {
        formattedValue = `${minutes}m`;
      } else {
        formattedValue = `${hours}h${minutes}m`;
      }

      return formattedValue;
    }
  }
};
</script>
