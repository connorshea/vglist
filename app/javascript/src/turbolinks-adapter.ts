import type Vue from "vue/types";
import type { VueConstructor } from "vue/types";

function handleVueDestructionOn(turbolinksEvent, vue: Vue) {
  document.addEventListener(turbolinksEvent, function teardown() {
    vue.$destroy();
    document.removeEventListener(turbolinksEvent, teardown);
  });
}

function plugin(Vue: VueConstructor, options) {
  // Install a global mixin
  Vue.mixin({
    beforeMount: function() {
      // If this is the root component, we want to cache the original element contents to replace later
      // We don't care about sub-components, just the root
      if (this == this.$root) {
        var destroyEvent =
          this.$options.turbolinksDestroyEvent || 'turbolinks:before-render';
        handleVueDestructionOn(destroyEvent, this);
        this.$originalEl = this.$el.outerHTML;
      }
    },

    destroyed: function() {
      // We only need to revert the html for the root component
      if (this == this.$root && this.$el) {
        this.$el.outerHTML = this.$originalEl;
      }
    }
  });
}

export default plugin;
