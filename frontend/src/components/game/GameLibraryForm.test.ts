import { describe, it, expect, vi, beforeEach } from "vitest";
import { mount, flushPromises } from "@vue/test-utils";
import GameLibraryForm from "./GameLibraryForm.vue";
import { GET_GAME_PURCHASE } from "@/graphql/queries/games";
import { ADD_GAME_TO_LIBRARY, UPDATE_GAME_IN_LIBRARY } from "@/graphql/mutations/games";

const { mockRequest } = vi.hoisted(() => ({
  mockRequest: vi.fn<(query: unknown, variables?: Record<string, unknown>) => Promise<unknown>>()
}));

vi.mock("@/graphql/client", () => ({
  gqlClient: { request: mockRequest }
}));

function gamePurchase(replayCount: number) {
  return {
    gamePurchase: {
      id: "7",
      completionStatus: "COMPLETED",
      rating: 90,
      hoursPlayed: 12,
      replayCount,
      comments: null,
      startDate: null,
      completionDate: null,
      platforms: { nodes: [] },
      stores: { nodes: [] }
    }
  };
}

async function mountForm(gamePurchaseId: string | null) {
  const wrapper = mount(GameLibraryForm, {
    props: {
      gameId: "1",
      gameName: "Outer Wilds",
      gamePurchaseId,
      gamePlatforms: [],
      allStores: [],
      storesLoading: false,
      removingFromLibrary: false
    }
  });
  await flushPromises();
  return wrapper;
}

function variablesFor(query: unknown): Record<string, unknown> | undefined {
  return mockRequest.mock.calls.find(([q]) => q === query)?.[1];
}

describe("GameLibraryForm replay count", () => {
  beforeEach(() => {
    localStorage.clear();
    mockRequest.mockReset();
    mockRequest.mockResolvedValue({});
  });

  it("has a labelled whole-number field", async () => {
    const wrapper = await mountForm(null);
    const label = wrapper.find('label[for="form-replay-count"]');
    const input = wrapper.find<HTMLInputElement>("#form-replay-count");
    expect(label.text()).toBe("Times replayed");
    expect(input.attributes("type")).toBe("number");
    expect(input.attributes("min")).toBe("0");
    expect(input.attributes("step")).toBe("1");
  });

  it("sends the replay count when adding a game", async () => {
    const wrapper = await mountForm(null);
    await wrapper.find("#form-replay-count").setValue("3");
    await wrapper.find(".form-btn-save").trigger("click");
    await flushPromises();
    expect(variablesFor(ADD_GAME_TO_LIBRARY)).toMatchObject({ gameId: "1", replayCount: 3 });
  });

  it("leaves the replay count out when adding with the field empty", async () => {
    const wrapper = await mountForm(null);
    await wrapper.find(".form-btn-save").trigger("click");
    await flushPromises();
    expect(variablesFor(ADD_GAME_TO_LIBRARY)).not.toHaveProperty("replayCount");
  });

  it("prefills the replay count when editing and saves the new value", async () => {
    mockRequest.mockImplementation((query) => Promise.resolve(query === GET_GAME_PURCHASE ? gamePurchase(2) : {}));
    const wrapper = await mountForm("7");
    const input = wrapper.find<HTMLInputElement>("#form-replay-count");
    expect(input.element.value).toBe("2");

    await input.setValue("4");
    await wrapper.find(".form-btn-save").trigger("click");
    await flushPromises();
    expect(variablesFor(UPDATE_GAME_IN_LIBRARY)).toMatchObject({ gamePurchaseId: "7", replayCount: 4 });
  });

  it("resets the replay count to zero when the field is cleared on edit", async () => {
    mockRequest.mockImplementation((query) => Promise.resolve(query === GET_GAME_PURCHASE ? gamePurchase(2) : {}));
    const wrapper = await mountForm("7");
    await wrapper.find("#form-replay-count").setValue("");
    await wrapper.find(".form-btn-save").trigger("click");
    await flushPromises();
    expect(variablesFor(UPDATE_GAME_IN_LIBRARY)).toMatchObject({ replayCount: 0 });
  });

  it("rounds down and clamps negative or fractional input", async () => {
    const wrapper = await mountForm(null);
    const input = wrapper.find<HTMLInputElement>("#form-replay-count");
    await input.setValue("2.7");
    await input.trigger("change");
    expect(input.element.value).toBe("2");
    await input.setValue("-3");
    await input.trigger("change");
    expect(input.element.value).toBe("0");
  });
});

describe("GameLibraryForm status and date defaults", () => {
  beforeEach(() => {
    localStorage.clear();
    mockRequest.mockReset();
    mockRequest.mockResolvedValue({});
  });

  const today = new Date().toISOString().slice(0, 10);

  function tile(wrapper: Awaited<ReturnType<typeof mountForm>>, label: string) {
    const found = wrapper.findAll(".form-tile").find((t) => t.text() === label);
    if (!found) throw new Error(`no ${label} tile`);
    return found;
  }

  it("fills an empty start date with today when you pick Playing, and Undo takes it back", async () => {
    const wrapper = await mountForm(null);
    await tile(wrapper, "Playing").trigger("click");

    expect(tile(wrapper, "Playing").attributes("aria-pressed")).toBe("true");
    expect(wrapper.find<HTMLInputElement>("#form-start-date").element.value).toBe(today);
    expect(wrapper.find(".form-hint").text()).toContain("Started set to today");

    await wrapper.find(".form-hint-undo").trigger("click");
    expect(wrapper.find<HTMLInputElement>("#form-start-date").element.value).toBe("");
    expect(wrapper.find(".form-hint").exists()).toBeFalsy();
    expect(tile(wrapper, "Playing").attributes("aria-pressed")).toBe("true");
  });

  it("fills the finished date for Completed and reverts the start date when switching from Playing", async () => {
    const wrapper = await mountForm(null);
    await tile(wrapper, "Playing").trigger("click");
    await tile(wrapper, "Completed").trigger("click");

    expect(wrapper.find<HTMLInputElement>("#form-start-date").element.value).toBe("");
    expect(wrapper.find<HTMLInputElement>("#form-completion-date").element.value).toBe(today);
    expect(wrapper.find(".form-hint").text()).toContain("Finished set to today");
  });

  it("leaves a date you already set alone", async () => {
    const wrapper = await mountForm(null);
    await wrapper.find("#form-start-date").setValue("2026-01-02");
    await tile(wrapper, "Playing").trigger("click");

    expect(wrapper.find<HTMLInputElement>("#form-start-date").element.value).toBe("2026-01-02");
    expect(wrapper.find(".form-hint").exists()).toBeFalsy();
  });

  it("clears the status on a second tap", async () => {
    const wrapper = await mountForm(null);
    await tile(wrapper, "Paused").trigger("click");
    await tile(wrapper, "Paused").trigger("click");
    await wrapper.find(".form-btn-save").trigger("click");
    await flushPromises();
    expect(variablesFor(ADD_GAME_TO_LIBRARY)).not.toHaveProperty("completionStatus");
  });
});

describe("GameLibraryForm sections", () => {
  beforeEach(() => {
    localStorage.clear();
    mockRequest.mockReset();
    mockRequest.mockResolvedValue({});
  });

  function toggle(wrapper: Awaited<ReturnType<typeof mountForm>>, controls: string) {
    return wrapper.find(`.form-section-toggle[aria-controls="${controls}"]`);
  }

  it("opens Progress by default in the drawer and summarises closed sections", async () => {
    const wrapper = await mountForm(null);
    expect(toggle(wrapper, "form-section-progress").attributes("aria-expanded")).toBe("true");
    expect(toggle(wrapper, "form-section-owned").attributes("aria-expanded")).toBe("false");
    expect(toggle(wrapper, "form-section-owned").text()).toContain("Not set");
    expect(toggle(wrapper, "form-section-review").text()).toContain("Optional");

    await toggle(wrapper, "form-section-review").trigger("click");
    expect(toggle(wrapper, "form-section-review").attributes("aria-expanded")).toBe("true");
  });

  it("starts with every section closed in the phone sheet", async () => {
    const wrapper = mount(GameLibraryForm, {
      props: {
        gameId: "1",
        gameName: "Outer Wilds",
        gamePurchaseId: null,
        gamePlatforms: [],
        allStores: [],
        storesLoading: false,
        removingFromLibrary: false,
        variant: "sheet"
      }
    });
    await flushPromises();
    expect(wrapper.findAll(".form-section-toggle[aria-expanded='true']")).toHaveLength(0);
  });

  it("shows hours and dates in the Progress summary once it's closed", async () => {
    const wrapper = await mountForm(null);
    await wrapper.find("#form-hours-played").setValue("12.5");
    await wrapper.find("#form-start-date").setValue("2026-10-30");
    await toggle(wrapper, "form-section-progress").trigger("click");
    expect(toggle(wrapper, "form-section-progress").text()).toContain("12.5 h · started Oct 30, 2026");
  });
});
