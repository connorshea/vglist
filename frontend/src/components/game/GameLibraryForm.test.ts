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
