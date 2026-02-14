import { createApp, h, type App } from "vue";

/**
 * This file is responsible for loading Vue components whenever we change pages
 * and an element with `data-vue-component` is there.
 *
 * It is somewhat cursed.
 */

// Store mounted apps to allow cleanup on Turbolinks navigation
const mountedApps = new Map<HTMLElement, App>();

(async function () {
  const callback = () => {
    const elems = Array.from(document.querySelectorAll("[data-vue-component]")) as HTMLElement[];
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
        render: () => h(comp, props),
      });

      // Mount directly on the element. Vue 3's mount() replaces the
      // element's innerHTML, which removes any placeholder content.
      app.mount(elem);
      mountedApps.set(elem, app);
    });
  };

  // Cleanup before Turbolinks caches the page. This runs right before
  // the DOM is swapped, so unmounting won't cause a visible flash.
  // It also ensures the cached page has clean placeholder state for
  // back/forward navigation.
  const cleanup = () => {
    mountedApps.forEach((app) => {
      app.unmount();
    });
    mountedApps.clear();
  };

  document.addEventListener("turbolinks:before-cache", cleanup);
  document.addEventListener("turbolinks:load", callback);
  callback();
})();
