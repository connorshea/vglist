document.addEventListener('turbolinks:load', () => {
  let toggleableButtons = getAll('.js-is-toggleable');

  if (toggleableButtons.length > 0) {
    toggleableButtons.forEach(function(el) {
      el.addEventListener('click', function(event) {
        let togglePartner = document.getElementsByClassName(
          el.dataset.togglePartner
        )[0];
        togglePartner.classList.toggle('is-hidden');
        el.classList.toggle('is-hidden');
      });
    });
  }

  function getAll(selector) {
    return Array.prototype.slice.call(document.querySelectorAll(selector), 0);
  }
});
