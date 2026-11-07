import { describe, it, expect, vi, beforeEach, afterEach } from "vitest";
import { mount, flushPromises } from "@vue/test-utils";
import { ref } from "vue";
import PasskeysCard from "./PasskeysCard.vue";
import {
  DELETE_PASSKEY,
  PASSKEY_REGISTRATION_OPTIONS,
  REGISTER_PASSKEY,
  RENAME_PASSKEY
} from "@/graphql/mutations/passkeys";
import type { GetCurrentUserPasskeysQuery } from "@/types/graphql";
import type * as SimpleWebAuthn from "@simplewebauthn/browser";

// ── Hoisted mocks ─────────────────────────────────────────────────

const { mockRequest, mockRefetch, mockStartRegistration, queryData, webauthn } = vi.hoisted(() => ({
  mockRequest: vi.fn<(query: unknown, variables?: Record<string, unknown>) => Promise<unknown>>(),
  mockRefetch: vi.fn<() => Promise<void>>(),
  mockStartRegistration: vi.fn<(options: { optionsJSON: unknown }) => Promise<unknown>>(),
  queryData: { value: null as GetCurrentUserPasskeysQuery | null },
  webauthn: { supported: true }
}));

vi.mock("@/graphql/client", () => ({
  gqlClient: { request: mockRequest }
}));

vi.mock("@/composables/useGraphQL", () => ({
  useQuery: () => ({
    data: ref(queryData.value),
    loading: ref(false),
    error: ref(null),
    refetch: mockRefetch
  })
}));

vi.mock("@simplewebauthn/browser", async (importOriginal) => ({
  ...(await importOriginal<typeof SimpleWebAuthn>()),
  browserSupportsWebAuthn: () => webauthn.supported,
  startRegistration: mockStartRegistration
}));

function passkey(id: string, nickname: string, extra: { backedUp?: boolean; lastUsedAt?: string | null } = {}) {
  return {
    id,
    nickname,
    backedUp: extra.backedUp ?? false,
    lastUsedAt: extra.lastUsedAt ?? null,
    createdAt: "2026-11-07T12:00:00Z"
  };
}

function withPasskeys(passkeys: ReturnType<typeof passkey>[]) {
  queryData.value = { currentUser: { id: "1", passkeys } };
}

function domError(name: string): Error {
  const error = new Error("browser error");
  error.name = name;
  return error;
}

function mountCard() {
  return mount(PasskeysCard, { attachTo: document.body });
}

function bodyButton(label: string): HTMLButtonElement {
  const button = Array.from(document.body.querySelectorAll<HTMLButtonElement>("button")).find(
    (b) => b.textContent?.trim() === label
  );
  if (!button) throw new Error(`no "${label}" button`);
  return button;
}

// Clicks "Add a passkey", then confirms the password in the dialog.
async function startAdding(wrapper: ReturnType<typeof mountCard>, password = "hunter2") {
  await wrapper.get("button.is-primary").trigger("click");
  const input = document.body.querySelector<HTMLInputElement>("#passkey-password");
  if (!input) throw new Error("no password input");
  input.value = password;
  input.dispatchEvent(new Event("input"));
  bodyButton("Continue").click();
  await flushPromises();
}

describe("PasskeysCard", () => {
  beforeEach(() => {
    mockRequest.mockReset();
    mockRefetch.mockReset();
    mockRefetch.mockResolvedValue(undefined);
    mockStartRegistration.mockReset();
    webauthn.supported = true;
    withPasskeys([]);
  });

  afterEach(() => {
    document.body.innerHTML = "";
  });

  it("shows an empty state when there are no passkeys", () => {
    const wrapper = mountCard();

    expect(wrapper.find(".pk-empty").text()).toContain("No passkeys yet");
  });

  it("lists passkeys with their sync state and usage", () => {
    withPasskeys([
      passkey("1", "MacBook Pro", { backedUp: true, lastUsedAt: new Date().toISOString() }),
      passkey("2", "Security key")
    ]);
    const wrapper = mountCard();

    const rows = wrapper.findAll(".pk-key");
    expect(rows).toHaveLength(2);
    expect(rows[0].text()).toContain("MacBook Pro");
    expect(rows[0].text()).toContain("Synced");
    expect(rows[0].text()).toContain("Added Nov 7, 2026 · Last used just now");
    expect(rows[1].text()).toContain("This device only");
    expect(rows[1].text()).toContain("Not used yet");
    expect(rows[1].find("button[aria-label='Remove Security key']").exists()).toBeTruthy();
  });

  it("disables adding when the browser doesn't support passkeys", () => {
    webauthn.supported = false;
    const wrapper = mountCard();

    expect(wrapper.get("button.is-primary").attributes("disabled")).toBeDefined();
    expect(wrapper.text()).toContain("This browser doesn't support passkeys.");
  });

  it("adds a passkey and then asks for a name", async () => {
    const registrationResponse = { id: "cred" };
    mockRequest.mockImplementation((query) => {
      if (query === PASSKEY_REGISTRATION_OPTIONS) {
        return Promise.resolve({ passkeyRegistrationOptions: { options: { challenge: "abc" }, errors: [] } });
      }
      if (query === REGISTER_PASSKEY) {
        return Promise.resolve({ registerPasskey: { passkey: passkey("9", "Mac"), errors: [] } });
      }
      if (query === RENAME_PASSKEY) {
        return Promise.resolve({ renamePasskey: { passkey: { id: "9", nickname: "Work laptop" }, errors: [] } });
      }
      return Promise.reject(new Error("unexpected query"));
    });
    mockStartRegistration.mockResolvedValue(registrationResponse);
    const wrapper = mountCard();

    await startAdding(wrapper);

    expect(mockStartRegistration).toHaveBeenCalledWith({ optionsJSON: { challenge: "abc" } });
    expect(mockRequest).toHaveBeenCalledWith(PASSKEY_REGISTRATION_OPTIONS, { currentPassword: "hunter2" });
    expect(mockRequest).toHaveBeenCalledWith(
      REGISTER_PASSKEY,
      expect.objectContaining({ response: registrationResponse })
    );
    expect(mockRefetch).toHaveBeenCalled();
    expect(document.body.textContent).toContain("Passkey added");

    const input = document.body.querySelector<HTMLInputElement>("#passkey-name");
    expect(document.activeElement).toBe(input);
    if (!input) throw new Error("no name input");
    input.value = "Work laptop";
    input.dispatchEvent(new Event("input"));
    bodyButton("Save name").click();
    await flushPromises();

    expect(mockRequest).toHaveBeenCalledWith(RENAME_PASSKEY, { id: "9", nickname: "Work laptop" });
  });

  it("says nothing when the browser prompt is cancelled", async () => {
    mockRequest.mockResolvedValue({ passkeyRegistrationOptions: { options: { challenge: "abc" }, errors: [] } });
    mockStartRegistration.mockRejectedValue(domError("NotAllowedError"));
    const wrapper = mountCard();

    await startAdding(wrapper);

    expect(wrapper.find(".pk-note").exists()).toBeFalsy();
    expect(mockRequest).not.toHaveBeenCalledWith(REGISTER_PASSKEY, expect.anything());
    expect(wrapper.get("button.is-primary").text()).toBe("Add a passkey");
  });

  it("explains a passkey that's already registered", async () => {
    mockRequest.mockResolvedValue({ passkeyRegistrationOptions: { options: { challenge: "abc" }, errors: [] } });
    mockStartRegistration.mockRejectedValue(domError("InvalidStateError"));
    const wrapper = mountCard();

    await startAdding(wrapper);

    expect(wrapper.get(".pk-note").text()).toBe("This passkey is already registered to your account.");
  });

  it("shows the server's reason when a passkey can't be added", async () => {
    mockRequest.mockResolvedValue({
      passkeyRegistrationOptions: { options: null, errors: ["Confirm your email address before adding a passkey."] }
    });
    const wrapper = mountCard();

    await startAdding(wrapper);

    expect(mockStartRegistration).not.toHaveBeenCalled();
    expect(document.body.querySelector("#passkey-password-error")?.textContent).toContain("Confirm your email address");
  });

  it("keeps the password dialog open when the password is wrong", async () => {
    mockRequest.mockResolvedValue({
      passkeyRegistrationOptions: { options: null, errors: ["Current password is incorrect."] }
    });
    const wrapper = mountCard();

    await startAdding(wrapper, "wrong");

    expect(mockStartRegistration).not.toHaveBeenCalled();
    expect(document.body.querySelector("#passkey-password-error")?.textContent).toBe("Current password is incorrect.");
    expect(document.body.querySelector("#passkey-password")?.getAttribute("aria-invalid")).toBe("true");
    expect(bodyButton("Continue")).toBeTruthy();
  });

  it("asks for the password before calling the server", async () => {
    const wrapper = mountCard();

    await startAdding(wrapper, "");

    expect(mockRequest).not.toHaveBeenCalled();
    expect(document.body.querySelector("#passkey-password-error")?.textContent).toBe("Enter your current password.");
  });

  it("removes a passkey after confirmation", async () => {
    withPasskeys([passkey("1", "MacBook Pro")]);
    mockRequest.mockResolvedValue({ deletePasskey: { deleted: true } });
    const wrapper = mountCard();

    await wrapper.get("button[aria-label='Remove MacBook Pro']").trigger("click");
    expect(document.body.textContent).toContain("Remove this passkey?");
    expect(mockRequest).not.toHaveBeenCalled();

    bodyButton("Remove passkey").click();
    await flushPromises();

    expect(mockRequest).toHaveBeenCalledWith(DELETE_PASSKEY, { id: "1" });
    expect(mockRefetch).toHaveBeenCalled();
  });
});
