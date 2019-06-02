<template>
  <div class="columns">
    <div class="column is-5-desktop">
      <a :href="user1Link">{{ user1.username }}</a>
      <div v-for="gamePurchase in user1Library" :key="gamePurchase.id">
        <a :href="gamePurchase.game_url">{{ gamePurchase.game.name }}</a>
        {{ gamePurchase.rating }}
      </div>
    </div>

    <div class="column is-5-desktop">
      <a :href="user2Link">{{ user2.username }}</a>
      <div v-for="gamePurchase in user2Library" :key="gamePurchase.id">
        <a :href="gamePurchase.game_url">{{ gamePurchase.game.name }}</a>
        {{ gamePurchase.rating }}
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
      user1Library: {},
      user2Library: {}
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
