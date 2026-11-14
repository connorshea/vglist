// Web Storage that never throws. Reading `window.localStorage` throws a
// SecurityError when site data is blocked, and some Android WebViews (in-app
// browsers) have it set to null. Either one used to throw before the app
// mounted and leave a blank page.
//
// When the browser's storage can't be used, values are kept in memory
// instead, so signing in still works until the page is reloaded.

export interface SafeStorage {
  getItem(key: string): string | null;
  // Returns false when the value couldn't be stored (e.g. storage is full).
  setItem(key: string, value: string): boolean;
  removeItem(key: string): void;
  keys(): string[];
  // Whether values outlive the page, i.e. the browser's storage is in use.
  isPersistent(): boolean;
}

export function createSafeStorage(getStorage: () => Storage | null | undefined): SafeStorage {
  const memory = new Map<string, string>();

  function backing(): Storage | null {
    try {
      const store = getStorage();
      if (!store) {
        return null;
      }
      // Some browsers hand out the object but throw on use.
      store.getItem("vglist:storage-probe");
      return store;
    } catch {
      return null;
    }
  }

  return {
    getItem(key) {
      const store = backing();
      if (!store) {
        return memory.get(key) ?? null;
      }
      try {
        return store.getItem(key);
      } catch {
        return null;
      }
    },
    setItem(key, value) {
      const store = backing();
      if (!store) {
        memory.set(key, value);
        return true;
      }
      try {
        store.setItem(key, value);
        return true;
      } catch {
        return false;
      }
    },
    removeItem(key) {
      memory.delete(key);
      try {
        backing()?.removeItem(key);
      } catch {
        // Nothing more to do.
      }
    },
    keys() {
      const store = backing();
      if (!store) {
        return [...memory.keys()];
      }
      try {
        const keys: string[] = [];
        for (let i = 0; i < store.length; i++) {
          const key = store.key(i);
          if (key !== null) {
            keys.push(key);
          }
        }
        return keys;
      } catch {
        return [];
      }
    },
    isPersistent() {
      return backing() !== null;
    }
  };
}

export const safeLocalStorage = createSafeStorage(() => window.localStorage);
export const safeSessionStorage = createSafeStorage(() => window.sessionStorage);
