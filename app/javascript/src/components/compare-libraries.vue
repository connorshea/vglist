<template>
  <vue-good-table
    :columns="columns"
    :rows="rows"
    :sort-options="{
      enabled: true,
      initialSortBy: { field: 'userOneRating', type: 'desc' }
    }"
  >
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
      }
      let rows = [];

      let gamePurchases = this.getGamePurchases();
      gamePurchases.forEach(gamePurchase => {
        let gameRow = { game: gamePurchase.game };
        if (gamePurchase.user_id === this.user1.id) {
          gameRow.userOneRating = gamePurchase.rating;
          gameRow.userTwoRating = null;
        }
        if (gamePurchase.user_id === this.user2.id) {
          gameRow.userOneRating = null;
          gameRow.userTwoRating = gamePurchase.rating;
        }
        rows.push(gameRow);
      });
      this.rows = rows;
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
    getGamePurchases() {
      if (this.user1Library === null && this.user2Library === null) {
        return [];
      }
      let metaLibrary = _.concat(this.user1Library, this.user2Library);

      // Get game purchases that exist in both users' libraries.
      let intersection = _.intersectionBy(
        this.user1Library,
        this.user2Library,
        'game.id'
      );
      let intersectingGameIds = intersection.map(gp => gp.game.id);

      let betterMetaLibrary = [];
      metaLibrary.forEach(gamePurchase => {
        let isFirstUser = gamePurchase.user_id === this.user1.id;
        let gameObj = {
          game: _.mapKeys(gamePurchase.game, (v, k) => _.camelCase(k))
        };
        isFirstUser
          ? (gameObj.userOneRating = gamePurchase.rating)
          : (gameObj.userTwoRating = gamePurchase.rating);
        betterMetaLibrary.push(gameObj);
      });

      // Removes duplicate game purchases based on the id of the associated game.
      metaLibrary = _.uniqBy(metaLibrary, gamePurchase => gamePurchase.game.id);
      metaLibrary = _.sortBy(metaLibrary, 'rating');
      return metaLibrary;
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
