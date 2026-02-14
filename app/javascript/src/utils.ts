import Rails from "@rails/ujs";

/**
 * A utility function to get all elements matching a selector as an array of HTMLElements.
 *
 * @example
 * import { getAll } from './utils';
 * const buttons = getAll('.my-button-class');
 *
 * @param {string} selector The CSS selector to match elements against.
 * @return {HTMLElement[]} An array of HTMLElements matching the selector.
 */
export const getAll = (selector: string): HTMLElement[] => {
  return Array.from(document.querySelectorAll(selector));
};

/**
 * A class for miscellaneous utility methods.
 */
export default class VglistUtils {
  /**
   * Fetches data from an endpoint and returns the raw response via a Promise.
   *
   * @param {string} route The URL path to send the request to.
   * @param {string} method The HTTP method to send the request with, e.g. 'GET', 'PUT', 'POST', 'DELETE'.
   * @param {string?} body The body of the request, optional.
   * @return {Promise<Response>} A promise that resolves to the response.
   */
  static async rawAuthenticatedFetch(
    route: string,
    method: string,
    body: string | null = null
  ): Promise<Response> {
    let requestBody: RequestInit = {
      method: method,
      headers: {
        "Content-Type": "application/json",
        "X-CSRF-Token": Rails.csrfToken()!,
        Accept: "application/json"
      },
      credentials: "same-origin"
    };

    if (body !== null) {
      requestBody.body = body;
    }

    return fetch(route, requestBody);
  }

  /**
   * Fetches data from an endpoint and returns the parsed JSON object via a Promise.
   *
   * @param {string} route The URL path to send the request to.
   * @param {string} method The HTTP method to send the request with, e.g. 'GET', 'PUT', 'POST', 'DELETE'.
   * @param {string?} body The body of the request, optional.
   * @return {Promise<T>} A promise that resolves to the JSON object after its been parsed.
   */
  static async authenticatedFetch<T>(
    route: string,
    method: "GET" | "PUT" | "POST" | "PATCH" | "DELETE",
    body: string | null = null
  ): Promise<T> {
    return this.rawAuthenticatedFetch(route, method, body).then(async (response) => {
      const json = await response.json();
      if (response.ok) {
        return Promise.resolve(json);
      }
      return await Promise.reject(json);
    });
  }
}
