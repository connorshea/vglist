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
      <span v-if="props.column.field == 'game'">
        <a :href="gameUrl(props.row.game.id)">{{ props.row.game.name }}</a>
      </span>
      <span v-else>{{ props.formattedRow[props.column.field] }}</span>
    </template>
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
          field: 'game',
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
      loadCheck: false
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
      let array = [];

      let gamePurchases = this.getGamePurchases();
      console.log(gamePurchases);
      gamePurchases.forEach(gamePurchase => {
        array.push({
          game: gamePurchase.game,
          userOneRating: 0,
          userTwoRating: 0
        });
      });
      this.rows = array;
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
      let libraries = _.concat(this.user1Library, this.user2Library);
      // Removes duplicate game purchases based on the id of the associated game.
      let uniqLibraries = _.uniqBy(
        libraries,
        gamePurchase => gamePurchase.game.id
      );
      uniqLibraries = _.sortBy(uniqLibraries, 'rating');
      return uniqLibraries;
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
