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
    const component = await import(`./components/${compName}.vue`);
    const props = JSON.parse(elem.dataset.vueProps ?? '{}');
    // console.log(`Loaded Vue "${compName}", rendering...`, { comp: component, compdef: component.default, props });
    createApp(component.default, props).mount(elem);
  });
}

document.addEventListener('turbolinks:load', initVue);
