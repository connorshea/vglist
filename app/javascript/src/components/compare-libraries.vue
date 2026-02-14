<template>
  <div class="compare-libraries-container">
    <template v-if="isLoading">
      <div class="has-text-centered py-20">
        <span>Loading...</span>
      </div>
    </template>
    <template v-else-if="groupedRows.length === 0 || groupedRows.every(g => g.children.length === 0)">
      <div class="has-text-centered py-20">
        <span class="has-text-grey">No games to compare.</span>
      </div>
    </template>
    <template v-else>
      <div v-for="group in groupedRows" :key="group.label" class="mb-20">
        <h3 class="title is-5 mb-10">{{ group.label }} ({{ group.children.length }})</h3>
        <table v-if="group.children.length > 0" class="table is-fullwidth is-striped" :class="{ 'is-dark': isDarkMode }">
          <thead>
            <tr>
              <th
                v-for="column in columns"
                :key="column.id"
                class="cursor-pointer"
                @click="toggleSort(column.id)"
              >
                <template v-if="column.id === 'userOneRating'">
                  <a :href="userUrl(user1.id)">{{ column.label }}</a>
                </template>
                <template v-else-if="column.id === 'userTwoRating'">
                  <a :href="userUrl(user2.id)">{{ column.label }}</a>
                </template>
                <template v-else>
                  {{ column.label }}
                </template>
                <span v-if="sortColumn === column.id" class="ml-5">
                  {{ sortDirection === 'asc' ? '▲' : '▼' }}
                </span>
              </th>
            </tr>
          </thead>
          <tbody>
            <tr v-for="row in sortRows(group.children)" :key="row.game.id">
              <td>
                <a :href="gameUrl(row.game.id)">{{ row.game.name }}</a>
              </td>
              <td>{{ row.userOneRating ?? '' }}</td>
              <td>{{ row.userTwoRating ?? '' }}</td>
            </tr>
          </tbody>
        </table>
      </div>
    </template>
  </div>
</template>

<script setup lang="ts">
import { concat } from 'lodash-es';
import { ref, computed, onMounted } from 'vue';

interface User {
  id: number;
  username: string;
  slug: string;
}

interface Props {
  user1: User;
  user2: User;
  user1LibraryUrl: string;
  user2LibraryUrl: string;
}

interface GamePurchase {
  id: number;
  user_id: number;
  game: {
    id: number;
    name: string;
  };
  rating: number | null;
}

interface GameRow {
  game: {
    id: number;
    name: string;
  };
  userOneRating: number | null | undefined;
  userTwoRating: number | null | undefined;
}

interface GroupedGameRow {
  label: string;
  children: GameRow[];
}

const props = defineProps<Props>();

// Reactive data
const user1Library = ref<GamePurchase[] | null>(null);
const user2Library = ref<GamePurchase[] | null>(null);
const groupedRows = ref<GroupedGameRow[]>([]);
const loadCheck = ref(false);
const isLoading = ref(true);
const sortColumn = ref<string>('userOneRating');
const sortDirection = ref<'asc' | 'desc'>('desc');

// Column definitions
const columns = computed(() => [
  {
    id: 'game.name',
    label: 'Game',
  },
  {
    id: 'userOneRating',
    label: props.user1.username,
  },
  {
    id: 'userTwoRating',
    label: props.user2.username,
  }
]);

// Dark mode detection
const isDarkMode = computed(() => {
  return window.matchMedia('(prefers-color-scheme: dark)').matches;
});

// Methods
function loadLibraries() {
  fetch(props.user1LibraryUrl, {
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
      user1Library.value = purchasedGames;
      loadRows();
    });

  fetch(props.user2LibraryUrl, {
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
      user2Library.value = purchasedGames;
      loadRows();
    });
}

function loadRows() {
  // Protects against the function being run when the first game library loads.
  if (loadCheck.value === false) {
    loadCheck.value = true;
    return;
  } else {
    isLoading.value = false;
  }
  groupedRows.value = getGamePurchases();
}

function gameUrl(gameId: number): string {
  return `${window.location.origin}/games/${gameId}`;
}

function userUrl(userId: number): string {
  return `${window.location.origin}/users/${userId}`;
}

function getGamePurchases(): GroupedGameRow[] {
  // Return early if both are null.
  if (user1Library.value === null && user2Library.value === null) {
    return [];
  }

  const libraries = [user1Library.value, user2Library.value].filter(Boolean) as GamePurchase[][];
  let metaLibrary = concat(...libraries);
  let betterMetaLibrary: GameRow[] = [];

  metaLibrary.forEach(gamePurchase => {
    let isFirstUser = gamePurchase.user_id === props.user1.id;

    // If the game isn't represented in the metaLibrary yet, append it to the existing array.
    if (
      !betterMetaLibrary.some(gp => gp.game.id === gamePurchase.game.id)
    ) {
      let gameRow: GameRow = {
        game: gamePurchase.game,
        userOneRating: undefined,
        userTwoRating: undefined
      };
      isFirstUser
        ? (gameRow.userOneRating = gamePurchase.rating)
        : (gameRow.userTwoRating = gamePurchase.rating);
      betterMetaLibrary.push(gameRow);
    } else {
      // If the game is already represented in the meta library, we need to modify it rather
      // than push a new entry.
      let index = betterMetaLibrary.findIndex(
        gp => gp.game.id === gamePurchase.game.id
      );
      if (index !== -1 && betterMetaLibrary[index]) {
        if (isFirstUser) {
          betterMetaLibrary[index].userOneRating = gamePurchase.rating;
        } else {
          betterMetaLibrary[index].userTwoRating = gamePurchase.rating;
        }
      }
    }
  });

  return groupGameRows(betterMetaLibrary);
}

/**
 * Group the table into three groups:
 *   - Games owned by both users
 *   - Games only owned by user1
 *   - Games only owned by user2
 */
function groupGameRows(metaLibrary: GameRow[]): GroupedGameRow[] {
  const sharedRows: GameRow[] = [];
  const user1Rows: GameRow[] = [];
  const user2Rows: GameRow[] = [];

  for (const gameRow of metaLibrary) {
    const ownedByUser1 = gameRow.userOneRating !== undefined;
    const ownedByUser2 = gameRow.userTwoRating !== undefined;

    if (ownedByUser1 && ownedByUser2) {
      sharedRows.push(gameRow);
    } else if (ownedByUser1) {
      user1Rows.push(gameRow);
    } else if (ownedByUser2) {
      user2Rows.push(gameRow);
    }
  }

  return [
    {
      label: 'Shared',
      children: sharedRows
    },
    {
      label: `Unique to ${props.user1.username}`,
      children: user1Rows
    },
    {
      label: `Unique to ${props.user2.username}`,
      children: user2Rows
    }
  ];
}

function toggleSort(columnId: string) {
  if (sortColumn.value === columnId) {
    sortDirection.value = sortDirection.value === 'asc' ? 'desc' : 'asc';
  } else {
    sortColumn.value = columnId;
    sortDirection.value = 'desc';
  }
}

function sortRows(rows: GameRow[]): GameRow[] {
  return [...rows].sort((a, b) => {
    let aVal: string | number | null | undefined;
    let bVal: string | number | null | undefined;

    if (sortColumn.value === 'game.name') {
      aVal = a.game.name.toLowerCase();
      bVal = b.game.name.toLowerCase();
    } else if (sortColumn.value === 'userOneRating') {
      aVal = a.userOneRating;
      bVal = b.userOneRating;
    } else if (sortColumn.value === 'userTwoRating') {
      aVal = a.userTwoRating;
      bVal = b.userTwoRating;
    }

    // Handle null/undefined values - always put them at the end
    if (aVal === null || aVal === undefined) {
      if (bVal === null || bVal === undefined) return 0;
      return 1;
    }
    if (bVal === null || bVal === undefined) {
      return -1;
    }

    if (aVal < bVal) return sortDirection.value === 'asc' ? -1 : 1;
    if (aVal > bVal) return sortDirection.value === 'asc' ? 1 : -1;
    return 0;
  });
}

// Lifecycle
onMounted(() => {
  loadLibraries();
});
</script>

<style scoped>
.compare-libraries-container {
  width: 100%;
}

.cursor-pointer {
  cursor: pointer;
}

.py-20 {
  padding-top: 20px;
  padding-bottom: 20px;
}

.mb-10 {
  margin-bottom: 10px;
}

.mb-20 {
  margin-bottom: 20px;
}

.ml-5 {
  margin-left: 5px;
}
</style>
