import Vue, { h } from 'vue';

/**
 * This file is responsible for loading Vue components whenever we change pages
 * and an element with `data-vue-component` is there.
 *
 * It is somewhat cursed.
 */
(async function() {
  const callback = () => {
    const elems = Array.from(document.querySelectorAll('[data-vue-component]'));
    elems.forEach(async (elem: HTMLElement) => {
      const el = elem;
      const compName = el.dataset.vueComponent;
      const comp$ = await import(`./components/${compName}.vue`);
      const comp = comp$.default;
      let props = {};
      if (el.dataset.vueProps) {
        props = JSON.parse(el.dataset.vueProps);
      }
      // console.log(`Loaded Vue "${compName}", rendering...`, { comp, props });
      // TODO: Make this use createApp() when we upgrade to Vue 3
      new Vue({
        el: elem,
        render: () => h(comp, { props: props })
      });
    });
  };
  document.addEventListener('turbolinks:load', callback);
  callback();
})();
