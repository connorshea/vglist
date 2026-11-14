import { describe, it, expect, beforeEach } from "vitest";
import { createSafeStorage, safeLocalStorage } from "./safe-storage";

function throwingStorage(): Storage {
  const fail = () => {
    throw new DOMException("The operation is insecure.", "SecurityError");
  };
  return {
    get length(): number {
      return fail();
    },
    key: fail,
    getItem: fail,
    setItem: fail,
    removeItem: fail,
    clear: fail
  };
}

describe("safe storage", () => {
  beforeEach(() => {
    localStorage.clear();
  });

  it("uses the browser's storage when it works", () => {
    expect(safeLocalStorage.setItem("a", "1")).toBeTruthy();
    expect(localStorage.getItem("a")).toBe("1");
    expect(safeLocalStorage.getItem("a")).toBe("1");
    expect(safeLocalStorage.keys()).toEqual(["a"]);
    expect(safeLocalStorage.isPersistent()).toBeTruthy();
    safeLocalStorage.removeItem("a");
    expect(localStorage.getItem("a")).toBeNull();
  });

  it.each([
    [
      "throws on access",
      () => {
        throw new DOMException("The operation is insecure.", "SecurityError");
      }
    ],
    ["is null", () => null],
    ["throws on use", throwingStorage]
  ])("falls back to memory when storage %s", (_label, getStorage) => {
    const store = createSafeStorage(getStorage);
    expect(store.isPersistent()).toBeFalsy();
    expect(store.getItem("a")).toBeNull();
    expect(store.setItem("a", "1")).toBeTruthy();
    expect(store.getItem("a")).toBe("1");
    expect(store.keys()).toEqual(["a"]);
    store.removeItem("a");
    expect(store.getItem("a")).toBeNull();
    expect(store.keys()).toEqual([]);
  });

  it("reports a failed write instead of throwing when storage is full", () => {
    const full: Storage = {
      length: 0,
      key: () => null,
      getItem: () => null,
      setItem: () => {
        throw new DOMException("Quota exceeded", "QuotaExceededError");
      },
      removeItem: () => undefined,
      clear: () => undefined
    };
    const store = createSafeStorage(() => full);
    expect(store.setItem("a", "1")).toBeFalsy();
    expect(store.getItem("a")).toBeNull();
  });
});
