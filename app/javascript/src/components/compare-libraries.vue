<template>
  <div>
    <a :href="user1Link">{{ user1.username }}</a>
    <a :href="user2Link">{{ user2.username }}</a>

    <div v-for="gamePurchase in user1Library" :key="gamePurchase.id">{{ gamePurchase.game_id }}</div>
    <div v-for="gamePurchase in user2Library" :key="gamePurchase.id">{{ gamePurchase.game_id }}</div>
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
    user1Library: {
      type: Array,
      required: true
    },
    user2Library: {
      type: Array,
      required: true
    }
  },
  data: function() {
    return {
      test: true
    };
  },
  methods: {
    test2() {
      console.log('test2');
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
