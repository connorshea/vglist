document.addEventListener('turbolinks:load', () => {
  let toggleableButtons = getAll('.js-is-toggleable');

  if (toggleableButtons.length > 0) {
    toggleableButtons.forEach(function(el) {
      // If there's a data-toggle-control attribute, that means there's a
      // third element that'll toggle the value. Otherwise, just have the
      // buttons themselves be the toggle.
      if (el.dataset.toggleControl) {
        let toggleControlEl: any = document.getElementsByClassName(el.dataset.toggleControl)[0];
        if (toggleControlEl.checked) {
          let [togglePartnerOnEl, togglePartnerOffEl] = getTogglePartners(toggleControlEl);
          togglePartnerOnEl.classList.remove('is-hidden');
          togglePartnerOffEl.classList.add('is-hidden');
        }
        toggleControlEl.addEventListener(toggleControlEl.dataset.toggleControlEventType, togglePartner);
      } else {
        el.addEventListener('click', function(_event) {
          let togglePartnerEl = document.getElementsByClassName(el.dataset.togglePartner)[0];
          togglePartnerEl.classList.toggle('is-hidden');
          el.classList.toggle('is-hidden');
        });
      }
    });
  }

  function getAll(selector: string) {
    return Array.prototype.slice.call(document.querySelectorAll(selector), 0);
  }

  function togglePartner(event): void {
    let [togglePartnerOnEl, togglePartnerOffEl] = getTogglePartners(event.target);
    togglePartnerOnEl.classList.toggle('is-hidden');
    togglePartnerOffEl.classList.toggle('is-hidden');
  }

  function getTogglePartners(toggleControlEl): [Element, Element] {
    let togglePartnerOnEl = document.getElementsByClassName(toggleControlEl.dataset.togglePartnerOn)[0];
    let togglePartnerOffEl = document.getElementsByClassName(toggleControlEl.dataset.togglePartnerOff)[0];

    return [togglePartnerOnEl, togglePartnerOffEl];
  }
});
