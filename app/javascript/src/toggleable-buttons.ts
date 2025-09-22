document.addEventListener('turbolinks:load', () => {
  const toggleableButtons = getAll('.js-is-toggleable');

  if (toggleableButtons.length > 0) {
    toggleableButtons.forEach(function(el) {
      // If there's a data-toggle-control attribute, that means there's a
      // third element that'll toggle the value. Otherwise, just have the
      // buttons themselves be the toggle.
      if (el.dataset.toggleControl) {
        const toggleControlEl: any = document.getElementsByClassName(el.dataset.toggleControl)[0];
        if (toggleControlEl.checked) {
          const [togglePartnerOnEl, togglePartnerOffEl] = getTogglePartners(toggleControlEl);
          togglePartnerOnEl.classList.remove('is-hidden');
          togglePartnerOffEl.classList.add('is-hidden');
        }
        toggleControlEl.addEventListener(toggleControlEl.dataset.toggleControlEventType, togglePartner);
      } else {
        el.addEventListener('click', function(_event) {
          const togglePartnerEl = document.getElementsByClassName(el.dataset.togglePartner)[0];
          togglePartnerEl.classList.toggle('is-hidden');
          el.classList.toggle('is-hidden');
        });
      }
    });
  }

  function getAll(selector: string): HTMLElement[] {
    return Array.from(document.querySelectorAll(selector));
  }

  function togglePartner(event): void {
    const [togglePartnerOnEl, togglePartnerOffEl] = getTogglePartners(event.target);
    togglePartnerOnEl.classList.toggle('is-hidden');
    togglePartnerOffEl.classList.toggle('is-hidden');
  }

  function getTogglePartners(toggleControlEl: HTMLElement): [Element, Element] {
    const { togglePartnerOn, togglePartnerOff } = toggleControlEl.dataset;
    return [
      document.getElementsByClassName(togglePartnerOn)[0],
      document.getElementsByClassName(togglePartnerOff)[0]
    ];
  }
});
