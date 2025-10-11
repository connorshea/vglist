<template>
  <vue-good-table
    :theme="theme"
    :columns="columns"
    :rows="rows"
    :sort-options="{
      enabled: true,
      initialSortBy: [
        { field: 'userOneRating', type: 'desc' },
        { field: 'userTwoRating', type: 'desc' }
      ]
    }"
    :groupOptions="{
      enabled: true
    }"
  >
    <template #table-column="props">
      <span v-if="props.column.field === 'userOneRating'">
        <a :href="userUrl(user1.id)">{{ props.column.label }}</a>
      </span>
      <span v-else-if="props.column.field === 'userTwoRating'">
        <a :href="userUrl(user2.id)">{{ props.column.label }}</a>
      </span>
      <span v-else>{{ props.column.label }}</span>
    </template>

    <template #table-row="props">
      <span v-if="props.column.field == 'game.name'">
        <a :href="gameUrl(props.row.game.id)">{{ props.row.game.name }}</a>
      </span>
      <span v-else>{{ props.formattedRow[props.column.field] }}</span>
    </template>

    <div slot="emptystate" class="vgt-center-align">
      <span v-if="isLoading">Loading...</span>
      <span v-else-if="!isLoading" class="vgt-text-disabled">No games to compare.</span>
    </div>
  </vue-good-table>
</template>

<script setup lang="ts">
import Rails from '@rails/ujs';
// @ts-expect-error - vue-good-table doesn't have TypeScript declarations
import { VueGoodTable } from 'vue-good-table';
import 'vue-good-table/dist/vue-good-table.css';
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
  mode: string;
  children: GameRow[];
}

const props = defineProps<Props>();

// Reactive data
const user1Library = ref<GamePurchase[] | null>(null);
const user2Library = ref<GamePurchase[] | null>(null);
const rows = ref<GroupedGameRow[]>([]);
const loadCheck = ref(false);
const isLoading = ref(true);

const columns = ref([
  {
    label: 'Game',
    field: 'game.name',
    type: 'text'
  },
  {
    label: `${props.user1.username}`,
    field: 'userOneRating',
    type: 'number'
  },
  {
    label: `${props.user2.username}`,
    field: 'userTwoRating',
    type: 'number'
  }
]);

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
  rows.value = getGamePurchases();
}

function getGameRatingInLibrary(userNumber: number, gameId: number): number | string {
  if (userNumber === 1 && user1Library.value) {
    let gamePurchaseInLibrary = user1Library.value.filter(
      gamePurchase => gamePurchase.game.id === gameId
    );
    if (
      gamePurchaseInLibrary.length > 0 &&
      gamePurchaseInLibrary[0] &&
      gamePurchaseInLibrary[0].rating !== null
    ) {
      return gamePurchaseInLibrary[0].rating!;
    }
  } else if (userNumber === 2 && user2Library.value) {
    let gamePurchaseInLibrary = user2Library.value.filter(
      gamePurchase => gamePurchase.game.id === gameId
    );
    if (
      gamePurchaseInLibrary.length > 0 &&
      gamePurchaseInLibrary[0] &&
      gamePurchaseInLibrary[0].rating !== null
    ) {
      return gamePurchaseInLibrary[0].rating!;
    }
  }
  return '-';
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
      !betterMetaLibrary
        .map(gp => gp.game.id)
        .includes(gamePurchase.game.id)
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
  let groupedMetaLibrary: GroupedGameRow[] = [];

  let sharedRows = metaLibrary.filter(gameRow => {
    return (
      gameRow.userOneRating !== undefined &&
      gameRow.userTwoRating !== undefined
    );
  });
  let user1Rows = metaLibrary.filter(gameRow => {
    return (
      gameRow.userOneRating !== undefined &&
      gameRow.userTwoRating === undefined
    );
  });
  let user2Rows = metaLibrary.filter(gameRow => {
    return (
      gameRow.userOneRating === undefined &&
      gameRow.userTwoRating !== undefined
    );
  });

  groupedMetaLibrary.push(
    {
      label: 'Shared',
      mode: 'span',
      children: sharedRows
    },
    {
      label: `Unique to ${props.user1.username}`,
      mode: 'span',
      children: user1Rows
    },
    {
      label: `Unique to ${props.user2.username}`,
      mode: 'span',
      children: user2Rows
    }
  );

  return groupedMetaLibrary;
}

// Computed properties
const user1Link = computed(() => {
  return `/users/${props.user1.slug}`;
});

const user2Link = computed(() => {
  return `/users/${props.user2.slug}`;
});

const theme = computed(() => {
  return window.matchMedia('(prefers-color-scheme: dark)').matches ? "nocturnal" : "default";
});

// Lifecycle
onMounted(() => {
  loadLibraries();
});
</script>
