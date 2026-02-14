import { getAll } from "./utils";

document.addEventListener("turbolinks:load", () => {
  const toggleableButtons = getAll(".js-is-toggleable");

  if (toggleableButtons.length > 0) {
    toggleableButtons.forEach(function (el) {
      // If there's a data-toggle-control attribute, that means there's a
      // third element that'll toggle the value. Otherwise, just have the
      // buttons themselves be the toggle.
      if (el.dataset.toggleControl) {
        const toggleControlEl: any = document.getElementsByClassName(el.dataset.toggleControl)[0];
        if (toggleControlEl.checked) {
          const [togglePartnerOnEl, togglePartnerOffEl] = getTogglePartners(toggleControlEl);
          togglePartnerOnEl.classList.remove("is-hidden");
          togglePartnerOffEl.classList.add("is-hidden");
        }
        toggleControlEl.addEventListener(
          toggleControlEl.dataset.toggleControlEventType,
          togglePartner,
        );
      } else {
        el.addEventListener("click", function (_event) {
          const togglePartnerEl = document.getElementsByClassName(el.dataset.togglePartner!)[0];
          togglePartnerEl?.classList.toggle("is-hidden");
          el.classList.toggle("is-hidden");
        });
      }
    });
  }

  function togglePartner(event: PointerEvent): void {
    const [togglePartnerOnEl, togglePartnerOffEl] = getTogglePartners(event.target as HTMLElement);
    togglePartnerOnEl.classList.toggle("is-hidden");
    togglePartnerOffEl.classList.toggle("is-hidden");
  }

  function getTogglePartners(toggleControlEl: HTMLElement): [Element, Element] {
    const { togglePartnerOn, togglePartnerOff } = toggleControlEl.dataset;

    if (!togglePartnerOn || !togglePartnerOff) {
      throw new Error(
        "Toggle control element is missing data-toggle-partner-on or data-toggle-partner-off attributes.",
      );
    }

    const togglePartnerOnEl = document.getElementsByClassName(togglePartnerOn)[0];
    const togglePartnerOffEl = document.getElementsByClassName(togglePartnerOff)[0];

    if (!togglePartnerOnEl || !togglePartnerOffEl) {
      throw new Error("Toggle partner elements not found.");
    }

    return [togglePartnerOnEl, togglePartnerOffEl];
  }
});
