import { createApp, h } from 'vue';

(async function() {
  const callback = () => {
    const elems = Array.from(document.querySelectorAll('[data-vue-component]'));
    elems.forEach(async elem => {
      const el = elem as HTMLElement;
      const compName = el.dataset.vueComponent;
      const comp$ = await import(`./components/${compName}.vue`);
      const comp = comp$.default;
      let props = {};
      if (el.dataset.vueProps) {
        props = JSON.parse(el.dataset.vueProps);
      }
      // console.log(`Loaded Vue \"${compName}\", rendering...`, { comp, props });
      const app = createApp({
        render() {
          return h(comp, props);
        }
      });
      app.mount(el);
    });
  };
  document.addEventListener('turbolinks:load', callback);
  callback();
})();
