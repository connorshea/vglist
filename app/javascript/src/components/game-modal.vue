<template>
  <div class="modal" :class="{ 'is-active': isActive } ">
    <div @click="onClose" class="modal-background"></div>
    <div class="modal-card">
      <header class="modal-card-head">
        <p class="modal-card-title">{{ modalTitle }}</p>
        <button @click="onClose" class="delete" aria-label="close"></button>
      </header>
      <section class="modal-card-body">
        
      </section>
      <footer class="modal-card-foot">
        <button @click="onSave" class="button is-success">Save changes</button>
        <button @click="onClose" class="button">Cancel</button>
      </footer>
    </div>
  </div>
</template>

<script>
import vSelect from 'vue-select';

export default {
  name: 'game-modal',
  components: {
    vSelect
  },
  props: {
    gamePurchase: {
      type: Object,
      required: true
    },
    isActive: {
      type: Boolean,
      required: true
    }
  },
  methods: {
    onClose() {
      this.$emit('close');
    },
    onSave() {
      this.$emit('close');
    }
  },
  computed: {
    modalTitle: function() {
      return this.gamePurchase.game !== undefined ? this.gamePurchase.game.name : 'Add a game to your library';
    }
  }
}
</script>
