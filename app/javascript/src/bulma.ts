// Make bulma's hamburger menu functional with some simple JavaScript.
let initBulma = () => {
  // Get all "navbar-burger" elements
  const $navbarBurgers = Array.prototype.slice.call(
    document.querySelectorAll('.navbar-burger'),
    0
  );

  // Check if there are any navbar burgers
  if ($navbarBurgers.length > 0) {
    // Add a click event on each of them
    $navbarBurgers.forEach(el => {
      el.addEventListener('click', () => {
        // Get the target from the "data-target" attribute
        const target = el.dataset.target;
        const $target = document.getElementById(target);

        // Toggle the "is-active" class on both the "navbar-burger" and the "navbar-menu"
        el.classList.toggle('is-active');
        $target.classList.toggle('is-active');
      });
    });
  }

  // Dropdowns
  let $dropdowns = getAll('.dropdown:not(.is-hoverable)');

  if ($dropdowns.length > 0) {
    $dropdowns.forEach(function($el) {
      $el.addEventListener('click', function(event) {
        // If the dropdown has the 'js-no-close-on-click' class,
        // it shouldn't be toggled when active.
        if (
          !$el.classList.contains('js-no-close-on-click') ||
          ($el.classList.contains('js-no-close-on-click') &&
            !$el.classList.contains('is-active'))
        ) {
          $el.classList.toggle('is-active');
        }
      });
    });

    // Close the dropdown if the user clicks outside the dropdown.
    document.addEventListener('click', function(event) {
      // If the user is clicking on something other than an element, return early.
      if (event.target !instanceof Element && event.target !instanceof HTMLDocument) {
        return;
      }
      // If the user clicks on the dropdown itself, don't close the dropdown.
      if ((event.target as Element).closest('.dropdown:not(.is-hoverable)')) {
        return;
      }
      closeDropdowns();
    });
  }

  function closeDropdowns() {
    $dropdowns.forEach(function($el) {
      $el.classList.remove('is-active');
    });
  }

  // Close dropdowns if ESC pressed
  document.addEventListener('keydown', function(event) {
    var e = event;
    if (e.code === 'Escape') {
      closeDropdowns();
    }
  });

  // Functions
  function getAll(selector) {
    return Array.prototype.slice.call(document.querySelectorAll(selector), 0);
  }

  // Close notifications when the delete button is clicked within a notification.
  let closeNotificationButtons = Array.prototype.slice.call(
    document.querySelectorAll('.notification > .delete'),
    0
  );

  closeNotificationButtons.forEach(el => {
    el.addEventListener('click', event => {
      let notification = event.target.closest('.notification');
      notification.parentNode.removeChild(notification);
    });
  });
};

document.addEventListener('turbolinks:load', initBulma);
window.addEventListener('load', function() {
  document.body.addEventListener('bulma:init', initBulma);
});
