import { getAll } from "./utils";

const toggleDropdown = function (this: HTMLElement, _event: MouseEvent) {
  // If the dropdown has the 'js-no-close-on-click' class,
  // it shouldn't be toggled when active.
  if (
    !this.classList.contains("js-no-close-on-click") ||
    (this.classList.contains("js-no-close-on-click") && !this.classList.contains("is-active"))
  ) {
    this.classList.toggle("is-active");
  }
};

// Make bulma's hamburger menu functional with some simple JavaScript.
const initBulma = () => {
  // Get all "navbar-burger" elements
  const navbarBurgers = getAll("a.navbar-burger");

  // Check if there are any navbar burgers
  if (navbarBurgers.length > 0) {
    // Add a click event on each of them
    navbarBurgers.forEach((el: HTMLElement) => {
      el.addEventListener("click", () => {
        // Get the target from the "data-target" attribute
        const target = document.getElementById(el.dataset.target!);

        // Toggle the "is-active" class on both the "navbar-burger" and the
        // "navbar-menu", and toggle the aria-expanded attribute.
        el.setAttribute("aria-expanded", (el.getAttribute("aria-expanded") === "false").toString());
        el.classList.toggle("is-active");
        target?.classList.toggle("is-active");
      });
    });
  }

  // Dropdowns
  const dropdowns = getAll(".dropdown:not(.is-hoverable):not(.dropdown-dynamic)");

  if (dropdowns.length > 0) {
    dropdowns.forEach(function (el) {
      el.addEventListener("click", toggleDropdown);
    });

    // Close the dropdown if the user clicks outside the dropdown.
    document.addEventListener("click", function (event) {
      // If the user is clicking on something other than an element, return early.
      if (!(event.target instanceof Element) && !(event.target instanceof HTMLDocument)) {
        return;
      }
      // If the user clicks on the dropdown itself, don't close the dropdown.
      if (
        (event.target as Element).closest(".dropdown:not(.is-hoverable):not(.dropdown-dynamic)")
      ) {
        return;
      }
      closeDropdowns();
    });
  }

  function closeDropdowns() {
    dropdowns.forEach(function (el) {
      el.classList.remove("is-active");
    });
  }

  // Close dropdowns if ESC pressed
  document.addEventListener("keydown", function (event) {
    if (event.code === "Escape") {
      closeDropdowns();
    }
  });

  // Close notifications when the delete button is clicked within a notification.
  const closeNotificationButtons = getAll(".notification > .delete");

  closeNotificationButtons.forEach((el) => {
    el.addEventListener("click", (event: MouseEvent) => {
      let notification = (event.target as HTMLElement).closest(".notification");
      notification?.parentNode?.removeChild(notification);
    });
  });
};

document.addEventListener("turbolinks:load", initBulma);
window.addEventListener("load", function () {
  document.body.addEventListener("bulma:init", initBulma);
});
