import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import { nextTick } from "vue";
import { detectSaveData, resetSaveDataForTests, useSaveData } from "./useSaveData";

class FakeConnection extends EventTarget {
  saveData = false;
}

class FakeMediaQueryList extends EventTarget {
  constructor(
    public media: string,
    public matches: boolean
  ) {
    super();
  }
}

let fakeConnection: FakeConnection;
let reducedData: FakeMediaQueryList;

beforeEach(() => {
  resetSaveDataForTests();
  fakeConnection = new FakeConnection();
  reducedData = new FakeMediaQueryList("(prefers-reduced-data: reduce)", false);
  Object.defineProperty(navigator, "connection", { value: fakeConnection, configurable: true });
  vi.stubGlobal(
    "matchMedia",
    vi.fn((query: string) => (query === reducedData.media ? reducedData : new FakeMediaQueryList(query, false)))
  );
});

afterEach(() => {
  Reflect.deleteProperty(navigator, "connection");
  vi.unstubAllGlobals();
});

describe("detectSaveData", () => {
  it("is false when the user hasn't asked to save data", () => {
    expect(detectSaveData()).toBeFalsy();
  });

  it("is true when Data Saver is on", () => {
    fakeConnection.saveData = true;
    expect(detectSaveData()).toBeTruthy();
  });

  it("is true when the user prefers reduced data", () => {
    reducedData.matches = true;
    expect(detectSaveData()).toBeTruthy();
  });

  it("is false when the browser has neither API", () => {
    Reflect.deleteProperty(navigator, "connection");
    vi.stubGlobal("matchMedia", undefined);
    expect(detectSaveData()).toBeFalsy();
  });
});

describe("useSaveData", () => {
  it("follows Data Saver being toggled while the page is open", async () => {
    const saveData = useSaveData();
    expect(saveData.value).toBeFalsy();

    fakeConnection.saveData = true;
    fakeConnection.dispatchEvent(new Event("change"));
    await nextTick();
    expect(saveData.value).toBeTruthy();
  });

  it("follows the reduced data preference changing", async () => {
    const saveData = useSaveData();

    reducedData.matches = true;
    reducedData.dispatchEvent(new Event("change"));
    await nextTick();
    expect(saveData.value).toBeTruthy();
  });

  it("shares one flag between callers", () => {
    expect(useSaveData().value).toBe(useSaveData().value);
    fakeConnection.saveData = true;
    fakeConnection.dispatchEvent(new Event("change"));
    expect(useSaveData().value).toBeTruthy();
  });
});
