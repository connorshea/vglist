import { describe, it, expect, vi, beforeEach, afterEach } from "vitest";
import { flushPromises, mount, RouterLinkStub } from "@vue/test-utils";
import { ref } from "vue";
import BackloggdImportCard from "./BackloggdImportCard.vue";

type Status = "QUEUED" | "RUNNING" | "SUCCEEDED" | "FAILED";

interface ImportState {
  id: string;
  username: string;
  status: Status;
  errorMessage: string | null;
  finishedAt: string | null;
  addedGames: { id: string; name: string; coverUrl: string | null }[];
  updatedGames: { id: string; name: string; coverUrl: string | null }[];
  unmatchedGames: { name: string; slug: string; url: string }[];
}

const { queryData, refetch, mutate, showSnackbar } = vi.hoisted(() => ({
  queryData: { current: null } as { current: unknown },
  refetch: vi.fn<() => Promise<void>>(),
  mutate: vi.fn<(variables: { userId: string; backloggdUsername: string }) => Promise<unknown>>(),
  showSnackbar: vi.fn<(message: string, type?: string) => void>()
}));

vi.mock("@/composables/useGraphQL", async () => {
  const { ref: vueRef } = await import("vue");
  const data = vueRef<unknown>(null);
  return {
    useQuery: () => {
      data.value = queryData.current;
      return {
        data,
        loading: vueRef(false),
        error: vueRef(null),
        refetch: async () => {
          await refetch();
          data.value = queryData.current;
        }
      };
    },
    useMutation: () => ({ mutate, loading: ref(false) })
  };
});

vi.mock("@/composables/useSnackbar", () => ({
  useSnackbar: () => ({ show: showSnackbar })
}));

function importState(overrides: Partial<ImportState> = {}): ImportState {
  return {
    id: "1",
    username: "Example",
    status: "SUCCEEDED",
    errorMessage: null,
    finishedAt: "2026-11-26T20:00:00Z",
    addedGames: [{ id: "1", name: "Hollow Knight", coverUrl: null }],
    updatedGames: [],
    unmatchedGames: [
      { name: "Some Obscure Game", slug: "some-obscure-game", url: "https://backloggd.com/games/some-obscure-game/" }
    ],
    ...overrides
  };
}

function setImport(state: ImportState | null) {
  queryData.current = { currentUser: { id: "7", backloggdImport: state } };
}

function mountCard() {
  return mount(BackloggdImportCard, {
    props: { userId: "7" },
    attachTo: document.body,
    global: { stubs: { RouterLink: RouterLinkStub } }
  });
}

describe("BackloggdImportCard", () => {
  beforeEach(() => {
    document.body.innerHTML = "";
    refetch.mockReset();
    refetch.mockResolvedValue(undefined);
    mutate.mockReset();
    showSnackbar.mockReset();
    setImport(null);
  });

  afterEach(() => {
    vi.useRealTimers();
  });

  it("can't import until a username is entered", () => {
    const wrapper = mountCard();

    expect(wrapper.get("button.is-primary").attributes("disabled")).toBeDefined();
    expect(wrapper.find('[role="status"]').exists()).toBeFalsy();
  });

  it("starts an import with the username", async () => {
    mutate.mockResolvedValue({ importBackloggdLibrary: { backloggdImport: { id: "1", status: "QUEUED" } } });
    const wrapper = mountCard();

    await wrapper.get("#backloggd-username").setValue("  Example ");
    await wrapper.get("form").trigger("submit");
    await flushPromises();

    expect(mutate).toHaveBeenCalledWith({ userId: "7", backloggdUsername: "Example" });
    expect(refetch).toHaveBeenCalled();
  });

  it("polls while the import runs, then shows the results", async () => {
    vi.useFakeTimers();
    setImport(importState({ status: "RUNNING", addedGames: [], unmatchedGames: [] }));
    const wrapper = mountCard();

    expect(wrapper.get('[role="status"]').text()).toContain("Importing from Example");
    expect(wrapper.get("button.is-primary").text()).toBe("Importing…");

    setImport(importState());
    await vi.advanceTimersByTimeAsync(3000);
    await flushPromises();

    expect(refetch).toHaveBeenCalledTimes(1);
    expect(wrapper.get('[role="status"]').text()).toContain("Added 1 game");
    expect(wrapper.get(".import-external-link").attributes("href")).toBe(
      "https://backloggd.com/games/some-obscure-game/"
    );

    await vi.advanceTimersByTimeAsync(10000);
    expect(refetch).toHaveBeenCalledTimes(1);
  });

  it("fills in the username from the last import", () => {
    setImport(importState());
    const wrapper = mountCard();

    expect(wrapper.get<HTMLInputElement>("#backloggd-username").element.value).toBe("Example");
  });

  it("shows why an import failed", () => {
    setImport(importState({ status: "FAILED", errorMessage: "Couldn't find a Backloggd user called Example." }));
    const wrapper = mountCard();

    expect(wrapper.get(".import-result.is-error").text()).toBe("Couldn't find a Backloggd user called Example.");
    expect(wrapper.text()).not.toContain("Backloggd import results");
  });

  it("shows the server's error when an import can't start", async () => {
    mutate.mockRejectedValue(new Error("An import from Backloggd is already running."));
    const wrapper = mountCard();

    await wrapper.get("#backloggd-username").setValue("Example");
    await wrapper.get("form").trigger("submit");
    await flushPromises();

    expect(showSnackbar).toHaveBeenCalledWith(expect.stringContaining("Failed to import from Backloggd"), "error");
  });
});
