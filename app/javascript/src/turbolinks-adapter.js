// Inspired by
// https://github.com/jeffreyguenther/vue-turbolinks/blob/master/index.js
// but changed to support going back to cached page with vue instance.
// Original version will keep instance created from cache along with new one.
// Source: https://github.com/jeffreyguenther/vue-turbolinks/issues/16#issuecomment-369136841 / https://gist.github.com/printercu/e202851c370ffc38bcdedeb8300d417e
var plugin;

plugin = {
  instances: [],
  bind: function() {
    // Destroy instances on current page when moving to another.
    document.addEventListener('turbolinks:before-cache', function() {
      return plugin.cleanupInstances();
    });
    // Destroy left instances when previous page has disabled caching.
    document.addEventListener('turbolinks:before-render', function() {
      return plugin.cleanupInstances();
    });
    // Clear instances on curent page which are not present anymore.
    return document.addEventListener('turbolinks:load', function() {
      return plugin.cleanupInstances(function(x) {
        return document.contains(x.$el);
      });
    });
  },
  cleanupInstances: function(keep_if) {
    var i, instance, len, ref, result;
    result = [];
    ref = plugin.instances;
    for (i = 0, len = ref.length; i < len; i++) {
      instance = ref[i];
      if (typeof keep_if === 'function' ? keep_if(instance) : void 0) {
        result.push(instance);
      } else {
        instance.$destroy();
      }
    }
    return (plugin.instances = result);
  },
  Mixin: {
    beforeMount: function() {
      // If this is the root component,
      // we want to cache the original element contents to replace later.
      // We don't care about sub-instances, just the root
      if (this === this.$root) {
        plugin.instances.push(this);
        return (this.$originalEl = this.$el.outerHTML);
      }
    },
    destroyed: function() {
      if (this === this.$root) {
        // We only need to revert the html for the root component.
        return (this.$el.outerHTML = this.$originalEl);
      }
    }
  },
  install: function(Vue, _options) {
    plugin.bind();
    return Vue.mixin(plugin.Mixin);
  }
};

export default plugin;
