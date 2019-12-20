/**
 * A class for miscellaneous utility methods.
 */
export default class VglistUtils {
  /**
   * Gets a cookie.
   * Original source: https://stackoverflow.com/a/21125098/7143763
   * 
   * @param {string} name 
   * @return {string | undefined} the cookie's contents
   */
  static getCookie(name: string) : string | undefined {
    let match = document.cookie.match(new RegExp(`(^| )${name}=([^;]+)`));
    if (match) { return match[2]; }
  }
}
