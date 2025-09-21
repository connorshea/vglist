import type Vue from "vue";

// Taken from here: https://github.com/jeffreyguenther/vue-turbolinks/issues/31#issuecomment-583403317 
function handleVueDestructionOn(turbolinksEvent, vue: Vue) {
  document.addEventListener(turbolinksEvent, function teardown() {
    vue.$destroy();
    document.removeEventListener(turbolinksEvent, teardown);
  });
}

function plugin(Vue, options) {
  // Install a global mixin
  Vue.mixin({
    beforeMount: function() {
      // If this is the root component, we want to cache the original element contents to replace later
      // We don't care about sub-components, just the root
      if (this == this.$root) {
        var destroyEvent =
          this.$options.turbolinksDestroyEvent || 'turbolinks:before-render';
        handleVueDestructionOn(destroyEvent, this);
      }
    },
  });
}

export default plugin;
