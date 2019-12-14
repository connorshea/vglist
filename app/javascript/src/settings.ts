import Rails from '@rails/ujs';

// This renders the user's API token on the Settings page when requested.
document.addEventListener('turbolinks:load', () => {
  let viewTokenButton = document.querySelector('.js-view-token-button');

  if (viewTokenButton) {
    viewTokenButton.addEventListener('click', () => {
      // For some reason TypeScript thinks dataset doesn't exist here.
      // @ts-ignore
      let tokenPath = viewTokenButton.dataset.tokenPath;

      fetch(tokenPath, {
        method: 'GET',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': Rails.csrfToken(),
          Accept: 'application/json'
        },
        credentials: 'same-origin'
      })
        .then(response => {
          return response.json().then(json => {
            if (response.ok) {
              return Promise.resolve(json);
            }
            return Promise.reject(json);
          });
        })
        .then(token => {
          // Display the token and disable the "View Token" button.
          document.querySelector('.js-token-holder').innerHTML = token;
          document.querySelector('.js-token-holder').classList.remove('is-hidden');
          // @ts-ignore
          viewTokenButton.disabled = true;
        })
        .catch(errors => {
          this.errors = errors;
        });
    });
  }
});
