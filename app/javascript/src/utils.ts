import Rails from '@rails/ujs';

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
  static async rawAuthenticatedFetch(route: string, method: string, body: string|null = null): Promise<Response> {
    let requestBody : RequestInit = {
      method: method,
      headers: {
        'Content-Type': 'application/json',
        'X-CSRF-Token': Rails.csrfToken(),
        Accept: 'application/json'
      },
      credentials: 'same-origin'
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
   * @return {Promise<any>} A promise that resolves to the JSON object after its been parsed.
   */
  static async authenticatedFetch(route: string, method: 'GET' | 'PUT' | 'POST' | 'PATCH' | 'DELETE', body: string|null = null): Promise<any> {
    // https://stackoverflow.com/questions/50041257/how-can-i-pass-json-body-of-fetch-response-to-throw-error-with-then
    return this.rawAuthenticatedFetch(route, method, body)
      .then(response => {
        return response.json().then(json => {
          if (response.ok) {
            return Promise.resolve(json);
          }
          return Promise.reject(json);
        });
      });
  }
}
