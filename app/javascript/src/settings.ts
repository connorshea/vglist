import VglistUtils from "./utils";

// This renders the user's API token on the Settings page when requested.
document.addEventListener("turbolinks:load", () => {
  let viewTokenButton = document.querySelector<HTMLButtonElement>("button.js-view-token-button");

  if (viewTokenButton !== null) {
    viewTokenButton.addEventListener("click", () => {
      const tokenPath = viewTokenButton.dataset.tokenPath;
      if (!tokenPath) {
        return;
      }

      VglistUtils.authenticatedFetch<string>(tokenPath, "GET")
        .then((token) => {
          // Display the token and disable the "View Token" button.
          const tokenHolder = document.querySelector<HTMLElement>(".js-token-holder");
          if (!tokenHolder) {
            return;
          }
          tokenHolder.innerHTML = token;
          tokenHolder.classList.remove("is-hidden");
          viewTokenButton.disabled = true;
        })
        .catch((errors) => {
          // TODO: Actually handle the errors here somehow.
          console.log(errors);
        });
    });
  }
});
