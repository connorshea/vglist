import { createApp } from 'vue';
import { getAll } from './utils';

/**
 * This file is responsible for loading Vue components whenever we change pages
 * and an element with `data-vue-component` is there.
 *
 * It is somewhat cursed.
 */
const initVue = function() {
  getAll('[data-vue-component]').forEach(async (elem: HTMLElement) => {
    const compName = elem.dataset.vueComponent;
    const comp$ = await import(`./components/${compName}.vue`);
    const props = JSON.parse(elem.dataset.vueProps ?? '{}');
    console.log(`Loaded Vue "${compName}", rendering...`, { comp: comp$, compdef: comp$.default, props });
    createApp(comp$.default, props).mount(elem);
  });
}

document.addEventListener('turbolinks:load', initVue);
