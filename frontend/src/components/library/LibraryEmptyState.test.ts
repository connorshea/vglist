import { describe, it, expect, vi, beforeEach } from "vitest";
import { mount, RouterLinkStub } from "@vue/test-utils";
import LibraryEmptyState from "./LibraryEmptyState.vue";

const { mockOpen } = vi.hoisted(() => ({ mockOpen: vi.fn<(query?: string) => void>() }));

vi.mock("@/composables/useSearchOverlay", () => ({
  useSearchOverlay: () => ({ open: mockOpen })
}));

function mountState(props: { error?: Error | null; libraryEmpty: boolean; ownLibrary?: boolean }) {
  return mount(LibraryEmptyState, {
    props: { error: null, ...props },
    global: { stubs: { RouterLink: RouterLinkStub } }
  });
}

describe("LibraryEmptyState", () => {
  beforeEach(() => {
    mockOpen.mockReset();
  });

  it("offers a Steam import and search when your own library is empty", async () => {
    const wrapper = mountState({ libraryEmpty: true, ownLibrary: true });

    expect(wrapper.text()).toContain("Your library is empty");
    expect(wrapper.findComponent(RouterLinkStub).props("to")).toEqual({ name: "settingsImport" });

    await wrapper.find("button").trigger("click");
    expect(mockOpen).toHaveBeenCalled();
  });

  it("just says so when someone else's library is empty", () => {
    const wrapper = mountState({ libraryEmpty: true });
    expect(wrapper.text()).toContain("No games in this library yet");
    expect(wrapper.findComponent(RouterLinkStub).exists()).toBeFalsy();
  });

  it("doesn't suggest an import when only the filters left nothing", () => {
    const wrapper = mountState({ libraryEmpty: false, ownLibrary: true });
    expect(wrapper.text()).toContain("No games match these filters");
  });

  it("shows a load error even on your own library", () => {
    const wrapper = mountState({ libraryEmpty: true, ownLibrary: true, error: new Error("Boom") });
    expect(wrapper.text()).toContain("Couldn't load this library");
    expect(wrapper.text()).toContain("Boom");
  });
});
