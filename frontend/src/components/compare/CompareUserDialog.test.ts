import { describe, it, expect, vi, beforeEach, afterEach } from "vitest";
import { mount, flushPromises } from "@vue/test-utils";
import CompareUserDialog from "./CompareUserDialog.vue";

const { mockRequest, mockAuth } = vi.hoisted(() => ({
  mockRequest: vi.fn<(query: unknown, variables?: Record<string, unknown>) => Promise<unknown>>(),
  mockAuth: { isAdmin: false }
}));

vi.mock("@/graphql/client", () => ({
  gqlClient: { request: mockRequest }
}));

vi.mock("@/stores/auth", () => ({
  useAuthStore: () => mockAuth
}));

function user(username: string, privacy = "PUBLIC_ACCOUNT", banned = false) {
  return { id: username, username, slug: username, avatarUrl: null, privacy, banned };
}

async function search(term: string) {
  const wrapper = mount(CompareUserDialog, {
    props: { modelValue: false, username: "connorshea", exclude: ["connorshea", "kestrel"] },
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

function optionNames() {
  return Array.from(document.body.querySelectorAll('[role="option"]')).map((option) =>
    option.lastElementChild?.textContent?.trim()
  );
}

describe("CompareUserDialog", () => {
  beforeEach(() => {
    vi.useFakeTimers();
    mockAuth.isAdmin = false;
    mockRequest.mockResolvedValue({
      userSearch: {
        nodes: [
          user("kestrel"),
          user("kessler"),
          user("keshi", "PRIVATE_ACCOUNT"),
          user("kes_banned", "PUBLIC_ACCOUNT", true)
        ]
      }
    });
  });

  afterEach(() => {
    vi.useRealTimers();
    document.body.innerHTML = "";
  });

  it("only offers users whose libraries can be compared", async () => {
    const wrapper = await search("kes");

    expect(optionNames()).toEqual(["kessler"]);
    wrapper.unmount();
  });

  it("offers private and banned users to admins", async () => {
    mockAuth.isAdmin = true;
    const wrapper = await search("kes");

    expect(optionNames()).toEqual(["kessler", "keshi", "kes_banned"]);
    wrapper.unmount();
  });
});
