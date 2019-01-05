<template>
  <li>
    <a v-bind:href="releaseLink">
      {{ release.name }}
    </a>
  </li>
</template>

<script>
export default {
  name: 'release-in-library',
  props: {
    release: {
      type: Object,
      required: true
    }
  },
  computed: {
    releaseLink() {
      return `/releases/${this.release.id}`;
    }
  }
}
</script>

