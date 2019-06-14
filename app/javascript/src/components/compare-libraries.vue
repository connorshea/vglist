<template>
  <vue-good-table
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
    <template slot="table-column" slot-scope="props">
      <span v-if="props.column.field === 'userOneRating'">
        <a :href="userUrl(user1.id)">{{ props.column.label }}</a>
      </span>
      <span v-else-if="props.column.field === 'userTwoRating'">
        <a :href="userUrl(user2.id)">{{ props.column.label }}</a>
      </span>
      <span v-else>{{ props.column.label }}</span>
    </template>

    <template slot="table-row" slot-scope="props">
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

<script>
import Rails from 'rails-ujs';
import { VueGoodTable } from 'vue-good-table';
import 'vue-good-table/dist/vue-good-table.css';

export default {
  name: 'compare-libraries',
  components: {
    VueGoodTable
  },
  props: {
    user1: {
      type: Object,
      required: true
    },
    user2: {
      type: Object,
      required: true
    },
    user1LibraryUrl: {
      type: String,
      required: true
    },
    user2LibraryUrl: {
      type: String,
      required: true
    }
  },
  data: function() {
    return {
      user1Library: null,
      user2Library: null,
      columns: [
        {
          label: 'Game',
          field: 'game.name',
          type: 'text'
        },
        {
          label: `${this.user1.username}`,
          field: 'userOneRating',
          type: 'number'
        },
        {
          label: `${this.user2.username}`,
          field: 'userTwoRating',
          type: 'number'
        }
      ],
      rows: [],
      loadCheck: false,
      isLoading: true
    };
  },
  created: function() {
    this.loadLibraries();
  },
  methods: {
    loadLibraries() {
      fetch(this.user1LibraryUrl, {
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
          this.user1Library = purchasedGames;
          this.loadRows();
        });

      fetch(this.user2LibraryUrl, {
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
          this.user2Library = purchasedGames;
          this.loadRows();
        });
    },
    loadRows() {
      // Protects against the function being run when the first game library loads.
      if (this.loadCheck === false) {
        this.loadCheck = true;
        return;
      } else {
        this.isLoading = false;
      }
      this.rows = this.getGamePurchases();
    },
    getGameRatingInLibrary(userNumber, gameId) {
      if (userNumber === 1) {
        let gamePurchaseInLibrary = this.user1Library.filter(
          gamePurchase => gamePurchase.game.id === gameId
        );
        if (
          gamePurchaseInLibrary.length > 0 &&
          gamePurchaseInLibrary[0].rating !== null
        ) {
          return gamePurchaseInLibrary[0].rating;
        }
      } else if (userNumber === 2) {
        let gamePurchaseInLibrary = this.user2Library.filter(
          gamePurchase => gamePurchase.game.id === gameId
        );
        if (
          gamePurchaseInLibrary.length > 0 &&
          gamePurchaseInLibrary[0].rating !== null
        ) {
          return gamePurchaseInLibrary[0].rating;
        }
      }
      return '-';
    },
    gameUrl(gameId) {
      return `${window.location.origin}/games/${gameId}`;
    },
    userUrl(userId) {
      return `${window.location.origin}/users/${userId}`;
    },
    getGamePurchases() {
      // Return early if both are null.
      if (this.user1Library === null && this.user2Library === null) {
        return [];
      }
      let metaLibrary = _.concat(this.user1Library, this.user2Library);
      let betterMetaLibrary = [];

      metaLibrary.forEach(gamePurchase => {
        let isFirstUser = gamePurchase.user_id === this.user1.id;

        // If the game isn't represented in the metaLibrary yet, append it to the existing array.
        if (
          !betterMetaLibrary
            .map(gp => gp.game.id)
            .includes(gamePurchase.game.id)
        ) {
          let gameRow = {
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
          isFirstUser
            ? (betterMetaLibrary[index].userOneRating = gamePurchase.rating)
            : (betterMetaLibrary[index].userTwoRating = gamePurchase.rating);
        }
      });

      return this.groupGameRows(betterMetaLibrary);
    },
    /**
     * Group the table into three groups:
     *   - Games owned by both users
     *   - Games only owned by user1
     *   - Games only owned by user2
     */
    groupGameRows(metaLibrary) {
      let groupedMetaLibrary = [];

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
          label: `Unique to ${this.user1.username}`,
          mode: 'span',
          children: user1Rows
        },
        {
          label: `Unique to ${this.user2.username}`,
          mode: 'span',
          children: user2Rows
        }
      );

      return groupedMetaLibrary;
    }
  },
  computed: {
    user1Link: function() {
      return `/users/${this.user1.slug}`;
    },
    user2Link: function() {
      return `/users/${this.user2.slug}`;
    }
  }
};
</script>
