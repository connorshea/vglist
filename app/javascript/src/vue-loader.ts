import { createApp, h, type App } from 'vue';

/**
 * This file is responsible for loading Vue components whenever we change pages
 * and an element with `data-vue-component` is there.
 *
 * It is somewhat cursed.
 */

// Store mounted apps to allow cleanup on Turbolinks navigation
const mountedApps = new Map<HTMLElement, App>();

(async function() {
  const callback = () => {
    const elems = Array.from(document.querySelectorAll('[data-vue-component]')) as HTMLElement[];
    elems.forEach(async (elem: HTMLElement) => {
      // Skip if already mounted
      if (mountedApps.has(elem)) {
        return;
      }

      const compName = elem.dataset.vueComponent;
      const comp$ = await import(`./components/${compName}.vue`);
      const comp = comp$.default;
      let props = {};
      if (elem.dataset.vueProps) {
        props = JSON.parse(elem.dataset.vueProps);
      }
      // console.log(`Loaded Vue "${compName}", rendering...`, { comp, props });

      const app = createApp({
        render: () => h(comp, props)
      });

      // Create a wrapper div to mount into (Vue 3 replaces the mount target)
      const wrapper = document.createElement('div');
      elem.appendChild(wrapper);

      app.mount(wrapper);
      mountedApps.set(elem, app);
    });
  };

  // Cleanup on Turbolinks navigation to prevent memory leaks
  const cleanup = () => {
    mountedApps.forEach((app) => {
      app.unmount();
    });
    mountedApps.clear();
  };

  document.addEventListener('turbolinks:before-visit', cleanup);
  document.addEventListener('turbolinks:load', callback);
  callback();
})();
