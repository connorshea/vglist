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
            <span class="icon" v-html="chevronDownIcon"></span>
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
    <template #table-row="props">
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

<script setup lang="ts">
import Rails from '@rails/ujs';
import { ref, computed, onMounted } from 'vue';
// @ts-expect-error - vue-good-table doesn't have TypeScript declarations
import { VueGoodTable } from 'vue-good-table';
import 'vue-good-table/dist/vue-good-table.css';

interface Props {
  gamePurchasesUrl: string;
  isEditable: boolean;
  rows: any[];
  isLoading: boolean;
  chevronDownIcon: string;
}

interface Column {
  label: string;
  field: string;
  type: 'text' | 'number' | 'decimal' | 'date';
  hideable?: boolean;
  index: number;
  hidden?: boolean;
  formatFn?: (value: any) => string;
  sortable?: boolean;
  dateInputFormat?: string;
  dateOutputFormat?: string;
  sortFn?: (x: any, y: any, col: any, rowX: any, rowY: any) => number;
  width?: string;
}

const props = defineProps<Props>();

const emit = defineEmits(['edit', 'delete', 'addGame', 'loaded', 'selectedGamePurchasesChanged']);

// Reactive data
const games = ref<any[]>([]);

// Methods

/**
 * Formats the hours played from a string representation of a float.
 *
 * This assumes the float has only one digit after the decimal point.
 * It will break if that changes.
 * 
 * @param value The string representation of the float to format.
 * @returns The formatted hours played string, e.g. '3h', '1h30m', or '5m'. Will return empty
 *   string for some cases, or if given an invalid value.
 */
function formatHoursPlayed(value: string | null): string {
  // If the value is null, 0, or in the format of '123.1', return an empty string.
  if (value === null || parseFloat(value) === 0 || !/^\d+\.\d$/.test(value)) {
    return '';
  }

  // Split the float between the whole number and the decimals.
  const [hours, numMinutes] = value.split('.').map(s => parseInt(s)) as [number, number];
  const minutes = Math.floor((numMinutes / 10) * 60);

  // Render 1h if there are 0 minutes, 1m if there are 0 hours, or 1h1m if there are both.
  if (minutes === 0) {
    return `${hours}h`;
  } else if (hours === 0) {
    return `${minutes}m`;
  } else {
    return `${hours}h${minutes}m`;
  }
}

// x - row1 value for column
// y - row2 value for column
function sortMultiselectColumn(x: any, y: any, col: any, rowX: any, rowY: any): number {
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
}

const columns = ref<Column[]>([
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
    formatFn: formatHoursPlayed,
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
    sortFn: sortMultiselectColumn,
    index: 7
  },
  {
    label: 'Stores',
    field: 'stores',
    type: 'text',
    hidden: true,
    sortable: true,
    sortFn: sortMultiselectColumn,
    index: 8
  },
  {
    label: 'Comments',
    field: 'comments',
    type: 'text',
    hidden: false,
    index: 9
  }
]);

type SortDirection = 'asc' | 'desc';
const sortDirection = ref<SortDirection>((localStorage.getItem('vglist:librarySortDirection') as SortDirection | null) ?? 'desc');
const sortColumn = ref(localStorage.getItem('vglist:librarySortColumn') ?? 'rating');

// Computed
const theme = computed(() => {
  return window.matchMedia('(prefers-color-scheme: dark)').matches ? "nocturnal" : "default";
});

// Methods
function onEdit(row: any) {
  emit('edit', row);
}

function onDelete(row: any) {
  if (window.confirm(`Remove ${row.game.name} from your library?`)) {
    // Post a delete request to the game purchase endpoint to delete the game from the library.
    const headers: HeadersInit = {
      Accept: 'application/json',
      'X-CSRF-Token': Rails.csrfToken()!
    };

    fetch(row.url, {
      method: 'DELETE',
      headers,
      credentials: 'same-origin'
    }).then(response => {
      if (response.ok) {
        // Emit a delete event to force the parent library component torefresh.
        emit('delete');
      }
    });
  }
}

function loadGames() {
  fetch(props.gamePurchasesUrl, {
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
      games.value = purchasedGames;
      emit('loaded');
    });
}

function addGame() {
  emit('addGame');
}

function toggleColumn(index: number, _event: Event) {
  const column = columns.value[index];
  if (column) {
    // Set hidden to the inverse of whatever it currently is.
    column.hidden = !column.hidden;
    
    const columnVisibility: Record<string, boolean> = {};
    // Filter this down to only columns that can be toggled.
    columns.value.filter(column => column.hideable === undefined).forEach(column => {
      columnVisibility[column.field] = !column.hidden;
    });
    localStorage.setItem('vglist:libraryColumns', JSON.stringify(columnVisibility));
  }
}

function selectionChanged(params: any) {
  emit('selectedGamePurchasesChanged', params.selectedRows);
}

function onSortChange(params: any) {
  // type is either 'asc' or 'desc'
  localStorage.setItem('vglist:librarySortDirection', params[0].type);
  localStorage.setItem('vglist:librarySortColumn', params[0].field);
}

// Initialize component
function initializeComponent() {
  loadGames();
  if (props.isEditable) {
    columns.value.push({
      label: 'Actions',
      field: 'after',
      width: '140px',
      hideable: false,
      sortable: false,
      index: 10,
      type: 'text'
    });
  }
}

// Lifecycle
onMounted(() => {
  // When the component is mounted, set the column visibility values
  // based on the libraryColumns value stored in localStorage.
  // Don't do anything if the value isn't defined.
  const libraryColumnsData = localStorage.getItem('vglist:libraryColumns');
  if (libraryColumnsData !== null) {
    // Update the visible columns to match the defined localStorage value.
    const libraryColumns = JSON.parse(libraryColumnsData);
    Object.entries(libraryColumns).forEach(([key, value]) => {
      const index = columns.value.findIndex(col => col.field === key);
      // Flip the value since the visibility value is stored as "whether
      // it's visible" but the hidden value is stored as "whether it's
      // hidden".
      if (index !== -1 && columns.value[index]) {
        columns.value[index].hidden = !(value as boolean);
      }
    });
  }

  const sortColumnData = localStorage.getItem('vglist:librarySortColumn');
  const sortDirectionData = localStorage.getItem('vglist:librarySortDirection') as SortDirection | null;

  if (sortDirectionData !== null || sortColumnData !== null) {
    if (sortColumnData) {
      sortColumn.value = sortColumnData;
    }
    if (sortDirectionData) {
      sortDirection.value = sortDirectionData;
    }
  }

  // Initialize the component
  initializeComponent();
});
</script>
