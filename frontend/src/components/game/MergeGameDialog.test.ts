import { describe, it, expect, vi, beforeEach, afterEach } from "vitest";
import { mount, flushPromises } from "@vue/test-utils";
import { ClientError } from "graphql-request";
import MergeGameDialog from "./MergeGameDialog.vue";
import { MERGE_GAMES } from "@/graphql/mutations/admin";

const { mockRequest } = vi.hoisted(() => ({
  mockRequest: vi.fn<(query: unknown, variables?: Record<string, unknown>) => Promise<unknown>>()
}));

vi.mock("@/graphql/client", () => ({
  gqlClient: { request: mockRequest }
}));

// graphql-request's types are stricter than what it builds from a response.
type ClientErrorResponse = ConstructorParameters<typeof ClientError>[0];

function candidate(id: string, name: string, releaseDate: string | null = null, ownerCount = 0) {
  return { id, name, releaseDate, coverUrl: null, ownerCount };
}

const SEARCH_RESULT = {
  gameSearch: {
    nodes: [
      candidate("1", "Half-Life 2 (duplicate)"),
      candidate("2", "Half-Life 2", "2004-11-16", 120),
      candidate("3", "Half-Life 2: Episode One", "2006-06-01", 1)
    ]
  }
};

async function openAndSearch(term: string) {
  const wrapper = mount(MergeGameDialog, {
    props: { modelValue: false, game: { id: "1", name: "Half-Life 2 (duplicate)", coverUrl: null } },
    attachTo: document.body
  });
  await wrapper.setProps({ modelValue: true });
  const input = document.body.querySelector<HTMLInputElement>('input[type="search"]');
  if (!input) throw new Error("no search input");
  input.value = term;
  input.dispatchEvent(new Event("input"));
  await vi.advanceTimersByTimeAsync(300);
  await flushPromises();
  return wrapper;
}

function options() {
  return Array.from(document.body.querySelectorAll<HTMLElement>('[role="option"]'));
}

function button(label: string) {
  const match = Array.from(document.body.querySelectorAll<HTMLButtonElement>("button")).find(
    (b) => b.textContent?.trim() === label
  );
  if (!match) throw new Error(`no ${label} button`);
  return match;
}

describe("MergeGameDialog", () => {
  beforeEach(() => {
    vi.useFakeTimers();
    mockRequest.mockReset();
    mockRequest.mockImplementation((query) =>
      Promise.resolve(
        query === MERGE_GAMES ? { mergeGames: { game: { id: "2", name: "Half-Life 2" } } } : SEARCH_RESULT
      )
    );
  });

  afterEach(() => {
    vi.useRealTimers();
    document.body.innerHTML = "";
  });

  it("never offers the game being merged", async () => {
    const wrapper = await openAndSearch("half");

    expect(options().map((o) => o.querySelector(".mg-result-name")?.textContent)).toEqual([
      "Half-Life 2",
      "Half-Life 2: Episode One"
    ]);
    expect(options()[0].textContent).toContain("2004 · 120 owners · ID 2");
    expect(options()[1].textContent).toContain("1 owner ·");
    wrapper.unmount();
  });

  it("asks for confirmation, then merges into the chosen game", async () => {
    const wrapper = await openAndSearch("half");

    options()[0].click();
    await flushPromises();

    // Nothing is merged until the admin confirms, and focus lands on Back.
    expect(mockRequest).not.toHaveBeenCalledWith(MERGE_GAMES, expect.anything());
    expect(document.activeElement?.textContent?.trim()).toBe("Back");
    expect(document.body.textContent).toContain("This can't be undone.");

    button("Merge and delete").click();
    await flushPromises();

    expect(mockRequest).toHaveBeenLastCalledWith(MERGE_GAMES, { gameToKeepId: "2", gameToMergeId: "1" });
    expect(wrapper.emitted("merged")).toEqual([[{ id: "2", name: "Half-Life 2" }]]);
    expect(wrapper.emitted("update:modelValue")).toEqual([[false]]);
    wrapper.unmount();
  });

  it("picks the highlighted game with the keyboard", async () => {
    const wrapper = await openAndSearch("half");
    const input = document.body.querySelector<HTMLInputElement>('input[type="search"]');

    input?.dispatchEvent(new KeyboardEvent("keydown", { key: "ArrowDown" }));
    input?.dispatchEvent(new KeyboardEvent("keydown", { key: "Enter" }));
    await flushPromises();

    expect(document.querySelector(".mg-pair-row.is-kept")?.textContent).toContain("Half-Life 2: Episode One");
    wrapper.unmount();
  });

  it("shows the server's error and stays open when the merge fails", async () => {
    const wrapper = await openAndSearch("half");
    mockRequest.mockImplementation((query) =>
      query === MERGE_GAMES
        ? Promise.reject(
            new ClientError(
              {
                status: 200,
                errors: [{ message: "You aren't allowed to merge these games." }]
              } as unknown as ClientErrorResponse,
              { query: "" }
            )
          )
        : Promise.resolve(SEARCH_RESULT)
    );

    options()[0].click();
    await flushPromises();
    button("Merge and delete").click();
    await flushPromises();

    expect(document.querySelector('[role="alert"]')?.textContent).toBe("You aren't allowed to merge these games.");
    expect(wrapper.emitted("merged")).toBeUndefined();
    expect(wrapper.emitted("update:modelValue")).toBeUndefined();
    wrapper.unmount();
  });

  it("goes back to the search from the confirmation step", async () => {
    const wrapper = await openAndSearch("half");

    options()[0].click();
    await flushPromises();
    button("Back").click();
    await flushPromises();

    expect(document.body.querySelector('input[type="search"]')).toBe(document.activeElement);
    wrapper.unmount();
  });
});
