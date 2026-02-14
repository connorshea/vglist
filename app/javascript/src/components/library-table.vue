<template>
  <div class="library-table-container">
    <!-- Table Actions -->
    <div class="library-table-actions level mb-10">
      <div class="level-left">
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
                v-for="column in table.getAllLeafColumns().filter(col => col.getCanHide())"
                :key="column.id"
              >
                <a @click="column.toggleVisibility()">
                  <input :checked="column.getIsVisible()" type="checkbox" />
                  {{ column.columnDef.header }}
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
    </div>

    <!-- Table -->
    <table class="table is-fullwidth is-striped library-table" :class="{ 'is-dark': isDarkMode }">
      <thead>
        <tr v-for="headerGroup in table.getHeaderGroups()" :key="headerGroup.id">
          <th
            v-for="header in headerGroup.headers"
            :key="header.id"
            :class="{ 'is-sortable': header.column.getCanSort(), 'cursor-pointer': header.column.getCanSort() }"
            @click="header.column.getCanSort() ? header.column.toggleSorting() : null"
          >
            <FlexRender
              v-if="!header.isPlaceholder"
              :render="header.column.columnDef.header"
              :props="header.getContext()"
            />
            <span v-if="header.column.getIsSorted()" class="ml-5">
              {{ header.column.getIsSorted() === 'asc' ? '▲' : '▼' }}
            </span>
          </th>
        </tr>
      </thead>
      <tbody>
        <template v-if="table.getRowModel().rows.length > 0">
          <tr v-for="row in table.getRowModel().rows" :key="row.id">
            <td v-for="cell in row.getVisibleCells()" :key="cell.id">
              <FlexRender
                :render="cell.column.columnDef.cell"
                :props="cell.getContext()"
              />
            </td>
          </tr>
        </template>
        <tr v-else>
          <td :colspan="table.getAllLeafColumns().length" class="has-text-centered py-20">
            <span v-if="isLoading">Loading...</span>
            <template v-else>
              <span class="has-text-grey">This library is empty.</span>
              <p v-if="isEditable" class="has-text-grey mt-10">
                Want to get a headstart?
                <a href="/settings/import">Connect your Steam account</a> and import your games to get started.
              </p>
            </template>
          </td>
        </tr>
      </tbody>
    </table>
  </div>
</template>

<script setup lang="ts">
import Rails from '@rails/ujs';
import { ref, computed, onMounted, watch, h } from 'vue';
import {
  useVueTable,
  getCoreRowModel,
  getSortedRowModel,
  FlexRender,
  createColumnHelper,
  type SortingState,
  type ColumnDef,
  type RowSelectionState,
  type VisibilityState,
} from '@tanstack/vue-table';

interface GamePurchaseRow {
  id: number;
  url: string;
  game_url: string;
  game: { id: number; name: string };
  rating: number | null;
  hours_played: string | null;
  completion_status: { label: string; value: string } | null;
  replay_count: number | null;
  start_date: string | null;
  completion_date: string | null;
  platforms: Array<{ id: number; name: string }>;
  stores: Array<{ id: number; name: string }>;
  comments: string | null;
}

interface Props {
  gamePurchasesUrl: string;
  isEditable: boolean;
  rows: GamePurchaseRow[];
  isLoading: boolean;
  chevronDownIcon: string;
}

const props = defineProps<Props>();

const emit = defineEmits(['edit', 'delete', 'addGame', 'loaded', 'selectedGamePurchasesChanged']);

// Reactive state
const games = ref<GamePurchaseRow[]>([]);
const sorting = ref<SortingState>([]);
const rowSelection = ref<RowSelectionState>({});
const columnVisibility = ref<VisibilityState>({});

// Dark mode detection
const isDarkMode = computed(() => {
  return window.matchMedia('(prefers-color-scheme: dark)').matches;
});

// Helper functions
function formatHoursPlayed(value: string | null): string {
  if (value === null || parseFloat(value) === 0 || !/^\d+\.\d$/.test(value)) {
    return '';
  }

  const [hours, numMinutes] = value.split('.').map(s => parseInt(s)) as [number, number];
  const minutes = Math.floor((numMinutes / 10) * 60);

  if (minutes === 0) {
    return `${hours}h`;
  } else if (hours === 0) {
    return `${minutes}m`;
  } else {
    return `${hours}h${minutes}m`;
  }
}

function formatDate(value: string | null): string {
  if (!value) return '';
  const date = new Date(value);
  return date.toLocaleDateString('en-US', { year: 'numeric', month: 'long', day: 'numeric' });
}

// Column definitions
const columnHelper = createColumnHelper<GamePurchaseRow>();

const baseColumns: ColumnDef<GamePurchaseRow, any>[] = [
  // Checkbox column for selection (if editable)
  ...(props.isEditable ? [columnHelper.display({
    id: 'select',
    header: ({ table }) => h('input', {
      type: 'checkbox',
      checked: table.getIsAllRowsSelected(),
      indeterminate: table.getIsSomeRowsSelected(),
      onChange: table.getToggleAllRowsSelectedHandler(),
    }),
    cell: ({ row }) => h('input', {
      type: 'checkbox',
      checked: row.getIsSelected(),
      disabled: !row.getCanSelect(),
      onChange: row.getToggleSelectedHandler(),
    }),
    enableSorting: false,
    enableHiding: false,
  })] : []),

  columnHelper.accessor(row => row.game.name, {
    id: 'game.name',
    header: 'Name',
    cell: info => h('a', { href: info.row.original.game_url }, info.getValue()),
    enableHiding: false,
  }),

  columnHelper.accessor('rating', {
    header: 'Rating',
    cell: info => info.getValue() ?? '',
  }),

  columnHelper.accessor('hours_played', {
    header: 'Hours Played',
    cell: info => formatHoursPlayed(info.getValue()),
  }),

  columnHelper.accessor(row => row.completion_status?.label ?? '', {
    id: 'completion_status.label',
    header: 'Completion Status',
    cell: info => info.getValue(),
  }),

  columnHelper.accessor('replay_count', {
    header: 'Replay Count',
    cell: info => info.getValue() ?? '',
  }),

  columnHelper.accessor('start_date', {
    header: 'Start Date',
    cell: info => formatDate(info.getValue()),
  }),

  columnHelper.accessor('completion_date', {
    header: 'Completion Date',
    cell: info => formatDate(info.getValue()),
  }),

  columnHelper.accessor('platforms', {
    header: 'Platforms',
    cell: info => {
      const platforms = info.getValue();
      if (!platforms || platforms.length === 0) return '';
      return h('div', platforms.map((p: { id: number; name: string }) =>
        h('p', { key: p.id }, h('a', { href: `/platforms/${p.id}` }, p.name))
      ));
    },
    sortingFn: (rowA, rowB) => {
      const a = rowA.original.platforms;
      const b = rowB.original.platforms;
      if (a.length === 0 && b.length === 0) return 0;
      if (b.length === 0) return 1;
      if (a.length === 0) return -1;
      return a[0]!.name.toLowerCase().localeCompare(b[0]!.name.toLowerCase());
    },
  }),

  columnHelper.accessor('stores', {
    header: 'Stores',
    cell: info => {
      const stores = info.getValue();
      if (!stores || stores.length === 0) return '';
      return h('div', stores.map((s: { id: number; name: string }) =>
        h('p', { key: s.id }, h('a', { href: `/stores/${s.id}` }, s.name))
      ));
    },
    sortingFn: (rowA, rowB) => {
      const a = rowA.original.stores;
      const b = rowB.original.stores;
      if (a.length === 0 && b.length === 0) return 0;
      if (b.length === 0) return 1;
      if (a.length === 0) return -1;
      return a[0]!.name.toLowerCase().localeCompare(b[0]!.name.toLowerCase());
    },
  }),

  columnHelper.accessor('comments', {
    header: 'Comments',
    cell: info => info.getValue() ?? '',
  }),

  // Actions column (if editable)
  ...(props.isEditable ? [columnHelper.display({
    id: 'actions',
    header: 'Actions',
    cell: ({ row }) => h('span', [
      h('a', { class: 'mr-5', onClick: () => onEdit(row.original) }, 'Edit'),
      h('a', { class: 'has-text-danger', onClick: () => onDelete(row.original) }, 'Remove'),
    ]),
    enableSorting: false,
    enableHiding: false,
  })] : []),
];

// Initialize table
const table = useVueTable({
  get data() { return props.rows; },
  columns: baseColumns,
  state: {
    get sorting() { return sorting.value; },
    get rowSelection() { return rowSelection.value; },
    get columnVisibility() { return columnVisibility.value; },
  },
  onSortingChange: updaterOrValue => {
    sorting.value = typeof updaterOrValue === 'function'
      ? updaterOrValue(sorting.value)
      : updaterOrValue;
    // Save to localStorage
    if (sorting.value[0]) {
      localStorage.setItem('vglist:librarySortColumn', sorting.value[0].id);
      localStorage.setItem('vglist:librarySortDirection', sorting.value[0].desc ? 'desc' : 'asc');
    }
  },
  onRowSelectionChange: updaterOrValue => {
    rowSelection.value = typeof updaterOrValue === 'function'
      ? updaterOrValue(rowSelection.value)
      : updaterOrValue;
    emit('selectedGamePurchasesChanged', table.getSelectedRowModel().rows.map(r => r.original));
  },
  onColumnVisibilityChange: updaterOrValue => {
    columnVisibility.value = typeof updaterOrValue === 'function'
      ? updaterOrValue(columnVisibility.value)
      : updaterOrValue;
    localStorage.setItem('vglist:libraryColumns', JSON.stringify(columnVisibility.value));
  },
  getCoreRowModel: getCoreRowModel(),
  getSortedRowModel: getSortedRowModel(),
  enableRowSelection: props.isEditable,
});

// Methods
function onEdit(row: GamePurchaseRow) {
  emit('edit', row);
}

function onDelete(row: GamePurchaseRow) {
  if (window.confirm(`Remove ${row.game.name} from your library?`)) {
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

// Lifecycle
onMounted(() => {
  // Initialize column visibility from localStorage
  const libraryColumnsData = localStorage.getItem('vglist:libraryColumns');
  if (libraryColumnsData !== null) {
    const libraryColumns = JSON.parse(libraryColumnsData);
    columnVisibility.value = libraryColumns;
  } else {
    // Set default visibility (hide some columns by default)
    columnVisibility.value = {
      'replay_count': false,
      'start_date': false,
      'completion_date': false,
      'platforms': false,
      'stores': false,
    };
  }

  // Initialize sorting from localStorage
  const sortColumnData = localStorage.getItem('vglist:librarySortColumn');
  const sortDirectionData = localStorage.getItem('vglist:librarySortDirection');

  if (sortColumnData) {
    sorting.value = [{
      id: sortColumnData,
      desc: sortDirectionData === 'desc'
    }];
  } else {
    // Default sort by rating descending
    sorting.value = [{ id: 'rating', desc: true }];
  }

  // Load games
  loadGames();
});
</script>

<style scoped>
.library-table-container {
  width: 100%;
}

.library-table {
  width: 100%;
}

.cursor-pointer {
  cursor: pointer;
}

.is-sortable:hover {
  background-color: rgba(0, 0, 0, 0.05);
}

.library-table.is-dark .is-sortable:hover {
  background-color: rgba(255, 255, 255, 0.05);
}

.py-20 {
  padding-top: 20px;
  padding-bottom: 20px;
}

.mt-10 {
  margin-top: 10px;
}

.ml-5 {
  margin-left: 5px;
}
</style>
