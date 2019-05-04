import Vue from 'vue/dist/vue.esm';

(async function() {
  let callback = () => {
    let elem$ = document.querySelectorAll('[data-vue-component]');
    let elems = Array.prototype.slice.call(elem$);
    elems.forEach(async elem => {
      let compName = elem.dataset.vueComponent;
      let comp$ = await import(`./components/${compName}.vue`);
      let comp = comp$.default;
      let props = null;
      if (elem.dataset.vueProps) {
        props = JSON.parse(elem.dataset.vueProps);
      }
      // console.log(`Loaded Vue "${compName}", rendering...`, { comp, props });
      let v = new Vue({
        el: elem,
        render: h =>
          h(comp, {
            props: props
          })
      });
    });
  };
  document.addEventListener('turbolinks:load', callback);
  callback();
})();
