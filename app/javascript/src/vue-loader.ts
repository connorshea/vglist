import Vue, { h } from 'vue';

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
      // console.log(`Loaded Vue "${compName}", rendering...`, { comp, props });
      new Vue({
        el: elem,
        render: () =>
          h(comp, {
            props: props
          })
      });
    });
  };
  document.addEventListener('turbolinks:load', callback);
  callback();
})();
