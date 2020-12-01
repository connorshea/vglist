<template>
  <vue-good-table
    :theme="theme"
    ref="game-library-table"
    :columns="columns"
    :rows="rows"
    :sort-options="{
      enabled: true,
      initialSortBy: { field: sortColumn, type: sortDirection }
    }"
    :search-options="{
      enabled: false
    }"
    :selectOptions="{
      enabled: isEditable,
      selectOnCheckboxOnly: true, // only select when checkbox is clicked instead of the row
      selectionInfoClass: 'selection-info-bar',
      selectionText: 'rows selected',
      clearSelectionText: 'clear',
      disableSelectInfo: true
    }"
    @on-selected-rows-change="selectionChanged"
    @on-sort-change="onSortChange"
  >
    <div slot="table-actions">
      <div class="dropdown is-right is-fullwidth-mobile mr-5 mr-0-mobile js-no-close-on-click">
        <div class="dropdown-trigger is-fullwidth-mobile">
          <button
            class="button is-fullwidth-mobile"
            aria-haspopup="true"
            aria-controls="dropdown-menu"
          >
            <span>Display columns</span>
            <span class="icon" v-html="this.chevronDownIcon"></span>
          </button>
        </div>
        <div class="dropdown-menu is-fullwidth-mobile" role="menu">
          <div class="dropdown-content">
            <div
              class="dropdown-item no-link-highlight"
              v-for="column in columns.filter(column => column.hideable !== false)"
              :key="column.index"
            >
              <a @click="toggleColumn(column.index, $event)">
                <input :checked="!column.hidden" type="checkbox" />
                {{ column.label }}
              </a>
            </div>
          </div>
        </div>
      </div>
      <button
        v-if="isEditable"
        @click="addGame()"
        class="button is-fullwidth-mobile mr-5 mr-0-mobile"
      >Add a game to your library</button>
    </div>
    <div slot="selected-row-actions"></div>
    <template slot="table-row" slot-scope="props">
      <span v-if="props.column.field == 'after'">
        <a class="mr-5" @click="onEdit(props.row)">Edit</a>
        <a class="has-text-danger" @click="onDelete(props.row)">Remove</a>
      </span>
      <span v-else-if="props.column.field == 'game.name'">
        <a :href="props.row.game_url">{{ props.row.game.name }}</a>
      </span>
      <span v-else-if="props.column.field == 'platforms'">
        <p v-for="platform in props.row.platforms" :key="platform.id">
          <a :href="`/platforms/${platform.id}`">{{ platform.name }}</a>
        </p>
      </span>
      <span v-else-if="props.column.field == 'stores'">
        <p v-for="store in props.row.stores" :key="store.id">
          <a :href="`/stores/${store.id}`">{{ store.name }}</a>
        </p>
      </span>
      <span v-else>{{ props.formattedRow[props.column.field] }}</span>
    </template>
    <div slot="emptystate" class="vgt-center-align">
      <span v-if="isLoading">Loading...</span>
      <span v-else-if="!isLoading" class="vgt-text-disabled">This library is empty.</span>
      <span v-if="!isLoading && isEditable" class="vgt-text-disabled">
        <p>
          Want to get a headstart?
          <a href="/settings/import">Connect your Steam account</a> and import your games to get started.
        </p>
      </span>
    </div>
  </vue-good-table>
</template>

<script lang="ts">
import Rails from '@rails/ujs';
import { VueGoodTable } from 'vue-good-table';
import 'vue-good-table/dist/vue-good-table.css';
import VglistUtils from '../utils';

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
    },
    chevronDownIcon: {
      type: String,
      required: true
    }
  },
  created: function() {
    this.loadGames();
    if (this.isEditable) {
      this.columns.push({
        label: 'Actions',
        field: 'after',
        width: '140px',
        hideable: false,
        sortable: false,
        index: 10
      });
    }
  },
  data: function() {
    return {
      columns: [
        {
          label: 'Name',
          field: 'game.name',
          type: 'text',
          hideable: false,
          index: 0
        },
        {
          label: 'Rating',
          field: 'rating',
          type: 'number',
          hidden: false,
          index: 1
        },
        {
          label: 'Hours Played',
          field: 'hours_played',
          type: 'decimal',
          formatFn: this.formatHoursPlayed,
          hidden: false,
          index: 2
        },
        {
          label: 'Completion Status',
          field: 'completion_status.label',
          type: 'text',
          hidden: false,
          index: 3
        },
        {
          label: 'Replay Count',
          field: 'replay_count',
          type: 'number',
          hidden: true,
          sortable: true,
          index: 4
        },
        {
          label: 'Start Date',
          field: 'start_date',
          type: 'date',
          dateInputFormat: 'yyyy-MM-dd',
          dateOutputFormat: 'MMMM d, yyyy',
          hidden: true,
          index: 5
        },
        {
          label: 'Completion Date',
          field: 'completion_date',
          type: 'date',
          dateInputFormat: 'yyyy-MM-dd',
          dateOutputFormat: 'MMMM d, yyyy',
          hidden: true,
          index: 6
        },
        {
          label: 'Platforms',
          field: 'platforms',
          type: 'text',
          hidden: true,
          sortable: true,
          sortFn: this.sortMultiselectColumn,
          index: 7
        },
        {
          label: 'Stores',
          field: 'stores',
          type: 'text',
          hidden: true,
          sortable: true,
          sortFn: this.sortMultiselectColumn,
          index: 8
        },
        {
          label: 'Comments',
          field: 'comments',
          type: 'text',
          hidden: false,
          index: 9
        }
      ],
      completionStatuses: [
        'unplayed',
        'in_progress',
        'dropped',
        'completed',
        'fully_completed',
        'not_applicable',
        'paused'
      ],
      sortDirection: localStorage.getItem('vglist:librarySortDirection') || 'desc',
      sortColumn: localStorage.getItem('vglist:librarySortColumn') || 'rating'
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
    openEditBar() {
      this.$emit('openEditBar');
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
    },
    // x - row1 value for column
    // y - row2 value for column
    sortMultiselectColumn(x, y, col, rowX, rowY) {
      let xEmpty = x.length === 0;
      let yEmpty = y.length === 0;

      if (xEmpty && yEmpty) {
        return 0;
      } else if (yEmpty) {
        return 1;
      } else if (xEmpty) {
        return -1;
      } else {
        let xName = x[0].name.toLowerCase();
        let yName = y[0].name.toLowerCase();
        return (xName < yName ? -1 : (xName > yName ? 1 : 0));
      }
    },
    toggleColumn(index, event) {
      // Set hidden to the inverse of whatever it currently is.
      this.$set(this.columns[index], 'hidden', !this.columns[index].hidden);
      let columnVisibility = {};
      // Filter this down to only columns that can be toggled.
      this.columns.filter(column => typeof column.hideable === 'undefined').forEach(column => {
        columnVisibility[column.field] = !column.hidden
      });
      localStorage.setItem('vglist:libraryColumns', JSON.stringify(columnVisibility));
    },
    selectionChanged(params) {
      this.$emit('selectedGamePurchasesChanged', params.selectedRows);
    },
    onSortChange(params) {
      // type is either 'asc' or 'desc'
      localStorage.setItem('vglist:librarySortDirection', params[0].type);
      localStorage.setItem('vglist:librarySortColumn', params[0].field);
    }
  },
  mounted: function() {
    // When the component is mounted, set the column visibility values
    // based on the libraryColumns value stored in localStorage.
    // Don't do anything if the value isn't defined.
    if (localStorage.getItem('vglist:libraryColumns') !== null) {
      // Update the visible columns to match the defined localStorage value.
      let libraryColumns = JSON.parse(localStorage.getItem('vglist:libraryColumns'));
      Object.entries(libraryColumns).forEach(([key, value]) => {
        let index = this.$data.columns.findIndex(col => col.field === key);
        // Flip the value since the visibility value is stored as "whether
        // it's visible" but the hidden value is stored as "whether it's
        // hidden".
        if (typeof index !== 'undefined') {
          this.$data.columns[index].hidden = !value;
        }
      });
    }

    if (
      localStorage.getItem('vglist:librarySortDirection') !== null ||
      localStorage.getItem('vglist:librarySortColumn') !== null
    ) {
      this.$data.sortColumn = localStorage.getItem('vglist:librarySortColumn');
      this.$data.sortDirection = localStorage.getItem('vglist:librarySortDirection');
    }
  },
  computed: {
    theme: function() {
      return window.matchMedia('(prefers-color-scheme: dark)').matches ? "nocturnal" : "default";
    }
  }
};
</script>
