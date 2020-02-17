import VglistUtils from './utils';

// This renders the user's API token on the Settings page when requested.
document.addEventListener('turbolinks:load', () => {
  let viewTokenButton = document.querySelector('.js-view-token-button');

  if (viewTokenButton) {
    viewTokenButton.addEventListener('click', () => {
      // For some reason TypeScript thinks dataset doesn't exist here.
      // @ts-ignore
      let tokenPath = viewTokenButton.dataset.tokenPath;

      VglistUtils.authenticatedFetch(tokenPath, 'GET').then(token => {
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
