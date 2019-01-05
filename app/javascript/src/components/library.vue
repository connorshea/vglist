<template>
  <ul>
    <release-in-library
      v-for="release in purchasedReleases"
      v-bind:key="release.id"
      v-bind:release="release"
    ></release-in-library>
  </ul>
</template>

<script>
import ReleaseInLibrary from './release-in-library.vue';

export default {
  components: {
    ReleaseInLibrary
  },
  props: {
    purchasedReleases: {
      type: Array,
      required: true
    }
  }
}
</script>

