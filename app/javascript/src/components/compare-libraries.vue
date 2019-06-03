<template>
  <div>
    <div class="columns column is-8 m-auto">
      <div class="column is-8-desktop"></div>
      <div class="column is-2-desktop">
        <a :href="user1Link">{{ user1.username }}</a>
      </div>
      <div class="column is-2-desktop">
        <a :href="user2Link">{{ user2.username }}</a>
      </div>
    </div>
    <div v-for="gamePurchase in gamePurchases" :key="gamePurchase.id">
      <div class="columns column is-8 m-auto">
        <div class="game-name column is-8-desktop">
          <a :href="gamePurchase.game_url">{{ gamePurchase.game.name }}</a>
        </div>
        <div
          class="user-1-rating column is-2-desktop"
        >{{ getGameRatingInLibrary(1, gamePurchase.game.id) }}</div>
        <div
          class="user-2-rating column is-2-desktop"
        >{{ getGameRatingInLibrary(2, gamePurchase.game.id) }}</div>
      </div>
    </div>
  </div>
</template>

<script>
import Rails from 'rails-ujs';

export default {
  name: 'compare-libraries',
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
      user2Library: null
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
        });
    },
    getGameRatingInLibrary(userNumber, gameId) {
      if (userNumber === 1) {
        let gamePurchaseInLibrary = this.user1Library.filter(
          gamePurchase => gamePurchase.game.id === gameId
        );
        if (gamePurchaseInLibrary.length > 0) {
          if (gamePurchaseInLibrary[0].rating !== null) {
            return gamePurchaseInLibrary[0].rating;
          }
        }
      } else if (userNumber === 2) {
        let gamePurchaseInLibrary = this.user2Library.filter(
          game => game.game.id === gameId
        );
        if (gamePurchaseInLibrary.length > 0) {
          if (gamePurchaseInLibrary[0].rating !== null) {
            return gamePurchaseInLibrary[0].rating;
          }
        }
      }
      return '-';
    }
  },
  computed: {
    user1Link: function() {
      return `/users/${this.user1.slug}`;
    },
    user2Link: function() {
      return `/users/${this.user2.slug}`;
    },
    gamePurchases: function() {
      if (this.user1Library === null || this.user2Library === null) {
        return [];
      }
      let libraries = _.concat(this.user1Library, this.user2Library);
      let uniqLibraries = _.uniqBy(
        libraries,
        gamePurchase => gamePurchase.game.id
      );

      return uniqLibraries;
    }
  }
};
</script>
