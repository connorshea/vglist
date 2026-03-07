import { createApp, h, type App } from "vue";

/**
 * This file is responsible for loading Vue components whenever we change pages
 * and an element with `data-vue-component` is there.
 *
 * It is somewhat cursed.
 */

// Store mounted apps to allow cleanup on Turbolinks navigation
const mountedApps = new Map<HTMLElement, App>();

// Use Vite's import.meta.glob for dynamic component imports.
const componentModules = import.meta.glob<{
  default: ReturnType<(typeof import("vue"))["defineComponent"]>;
}>("./components/**/*.vue");

(function () {
  const callback = () => {
    const elems = Array.from(document.querySelectorAll("[data-vue-component]")) as HTMLElement[];
    elems.forEach(async (elem: HTMLElement) => {
      // Skip if already mounted
      if (mountedApps.has(elem)) {
        return;
      }

      const compName = elem.dataset.vueComponent;
      const modulePath = `./components/${compName}.vue`;
      const loader = componentModules[modulePath];

      if (!loader) {
        console.error(`Vue component "${compName}" not found at ${modulePath}`);
        return;
      }

      const comp$ = await loader();
      const comp = comp$.default;
      let props = {};
      if (elem.dataset.vueProps) {
        props = JSON.parse(elem.dataset.vueProps);
      }

      const app = createApp({
        render: () => h(comp, props)
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
