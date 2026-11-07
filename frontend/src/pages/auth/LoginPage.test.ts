import { describe, it, expect, vi, beforeEach, afterEach } from "vitest";
import { mount, flushPromises } from "@vue/test-utils";
import LoginPage from "./LoginPage.vue";

// ── Hoisted mocks ─────────────────────────────────────────────────

const { mockRoute, mockPush, mockSignIn, mockSignInWithPasskey, webauthn } = vi.hoisted(() => ({
  mockRoute: { query: {} },
  mockPush: vi.fn<() => void>(),
  mockSignIn: vi.fn<(email: string, password: string) => Promise<{ success: boolean; errors: string[] }>>(),
  mockSignInWithPasskey:
    vi.fn<
      (options?: {
        useBrowserAutofill?: boolean;
      }) => Promise<
        | { status: "success"; username: string }
        | { status: "cancelled" }
        | { status: "error"; stage: "options" | "browser" | "verify"; errors: string[] }
      >
    >(),
  webauthn: { supported: false, autofill: false }
}));

vi.mock("@simplewebauthn/browser", () => ({
  browserSupportsWebAuthn: () => webauthn.supported,
  browserSupportsWebAuthnAutofill: () => Promise.resolve(webauthn.autofill),
  WebAuthnAbortService: { cancelCeremony: vi.fn<() => void>() }
}));

vi.mock("vue-router", () => ({
  useRouter: () => ({ push: mockPush }),
  useRoute: () => mockRoute
}));

vi.mock("@/composables/useAuth", () => ({
  useAuth: () => ({
    signIn: mockSignIn,
    signInWithPasskey: mockSignInWithPasskey
  })
}));

const mountOptions = {
  global: {
    stubs: {
      RouterLink: true
    }
  }
};

// ── Tests ─────────────────────────────────────────────────────────

describe("LoginPage", () => {
  beforeEach(() => {
    mockRoute.query = {};
    mockPush.mockReset();
    mockSignIn.mockReset();
    mockSignInWithPasskey.mockReset();
    webauthn.supported = false;
    webauthn.autofill = false;
  });

  it("renders the form with email and password fields", () => {
    const wrapper = mount(LoginPage, mountOptions);

    expect(wrapper.find("h1").text()).toBe("Sign in");
    expect(wrapper.find("input[type='email']").exists()).toBeTruthy();
    expect(wrapper.find("input[type='password']").exists()).toBeTruthy();
    expect(wrapper.find("button[type='submit']").text()).toBe("Sign in");
  });

  it("calls signIn with email and password on submit", async () => {
    mockSignIn.mockResolvedValue({ success: true, errors: [] });
    const wrapper = mount(LoginPage, mountOptions);

    await wrapper.find("input[type='email']").setValue("test@example.com");
    await wrapper.find("input[type='password']").setValue("password123");
    await wrapper.find("form").trigger("submit");
    await flushPromises();

    expect(mockSignIn).toHaveBeenCalledWith("test@example.com", "password123");
  });

  it("redirects to / on successful sign-in with no redirect query", async () => {
    mockSignIn.mockResolvedValue({ success: true, errors: [] });
    const wrapper = mount(LoginPage, mountOptions);

    await wrapper.find("input[type='email']").setValue("test@example.com");
    await wrapper.find("input[type='password']").setValue("password123");
    await wrapper.find("form").trigger("submit");
    await flushPromises();

    expect(mockPush).toHaveBeenCalledWith("/");
  });

  it("redirects to the redirect query param on successful sign-in", async () => {
    mockRoute.query = { redirect: "/games/42" };
    mockSignIn.mockResolvedValue({ success: true, errors: [] });
    const wrapper = mount(LoginPage, mountOptions);

    await wrapper.find("input[type='email']").setValue("test@example.com");
    await wrapper.find("input[type='password']").setValue("password123");
    await wrapper.find("form").trigger("submit");
    await flushPromises();

    expect(mockPush).toHaveBeenCalledWith("/games/42");
  });

  it("ignores unsafe redirect values (open redirect prevention)", async () => {
    mockRoute.query = { redirect: "//evil.com" };
    mockSignIn.mockResolvedValue({ success: true, errors: [] });
    const wrapper = mount(LoginPage, mountOptions);

    await wrapper.find("input[type='email']").setValue("test@example.com");
    await wrapper.find("input[type='password']").setValue("password123");
    await wrapper.find("form").trigger("submit");
    await flushPromises();

    expect(mockPush).toHaveBeenCalledWith("/");
  });

  it("shows errors on failed sign-in", async () => {
    mockSignIn.mockResolvedValue({ success: false, errors: ["Invalid email or password."] });
    const wrapper = mount(LoginPage, mountOptions);

    await wrapper.find("input[type='email']").setValue("test@example.com");
    await wrapper.find("input[type='password']").setValue("wrong");
    await wrapper.find("form").trigger("submit");
    await flushPromises();

    expect(wrapper.find(".notification.is-danger").text()).toContain("Invalid email or password.");
  });

  it("shows loading state while submitting", async () => {
    // Never resolve so we can inspect loading state
    mockSignIn.mockReturnValue(new Promise<{ success: boolean; errors: string[] }>(() => {}));
    const wrapper = mount(LoginPage, mountOptions);

    await wrapper.find("input[type='email']").setValue("test@example.com");
    await wrapper.find("input[type='password']").setValue("password123");
    await wrapper.find("form").trigger("submit");

    expect(wrapper.find("button[type='submit']").text()).toBe("Signing in...");
    expect(wrapper.find("button[type='submit']").attributes("disabled")).toBeDefined();
  });
});

describe("LoginPage passkeys", () => {
  beforeEach(() => {
    mockRoute.query = {};
    mockPush.mockReset();
    mockSignInWithPasskey.mockReset();
    webauthn.supported = true;
    webauthn.autofill = false;
  });

  it("hides the passkey button when the browser doesn't support WebAuthn", () => {
    webauthn.supported = false;
    const wrapper = mount(LoginPage, mountOptions);

    expect(wrapper.find(".auth-passkey").exists()).toBeFalsy();
  });

  it("offers passkeys in the email field's autofill", () => {
    const wrapper = mount(LoginPage, mountOptions);

    expect(wrapper.find("#login-email").attributes("autocomplete")).toBe("username webauthn");
  });

  describe("after a passkey sign-in", () => {
    beforeEach(() => {
      vi.useFakeTimers();
      mockSignInWithPasskey.mockResolvedValue({ status: "success", username: "connor" });
    });

    afterEach(() => {
      vi.useRealTimers();
    });

    it("confirms the passkey worked, then redirects", async () => {
      mockRoute.query = { redirect: "/settings" };
      const wrapper = mount(LoginPage, { ...mountOptions, attachTo: document.body });

      await wrapper.find(".auth-passkey").trigger("click");
      await flushPromises();

      expect(mockSignInWithPasskey).toHaveBeenCalledWith();
      const success = wrapper.find(".auth-success");
      expect(success.text()).toContain("You're signed in");
      expect(success.text()).toContain("Welcome back, connor!");
      expect(success.text()).toContain("Taking you back to where you were");
      expect(document.activeElement).toBe(success.find("h1").element);
      expect(wrapper.find("form").exists()).toBeFalsy();
      expect(mockPush).not.toHaveBeenCalled();

      vi.advanceTimersByTime(4000);
      expect(mockPush).toHaveBeenCalledWith("/settings");
      wrapper.unmount();
    });

    it("doesn't redirect after leaving the page", async () => {
      const wrapper = mount(LoginPage, mountOptions);

      await wrapper.find(".auth-passkey").trigger("click");
      await flushPromises();
      wrapper.unmount();
      vi.advanceTimersByTime(4000);

      expect(mockPush).not.toHaveBeenCalled();
    });
  });

  it("shows a waiting state while the browser prompt is open", async () => {
    mockSignInWithPasskey.mockReturnValue(new Promise(() => {}));
    const wrapper = mount(LoginPage, mountOptions);

    await wrapper.find(".auth-passkey").trigger("click");

    const button = wrapper.find(".auth-passkey");
    expect(button.text()).toBe("Waiting for your passkey…");
    expect(button.attributes("disabled")).toBeDefined();
    expect(wrapper.find("#passkey-status").text()).toContain("Finish in your browser's prompt");
  });

  it("stays quiet when the prompt is cancelled", async () => {
    mockSignInWithPasskey.mockResolvedValue({ status: "cancelled" });
    const wrapper = mount(LoginPage, mountOptions);

    await wrapper.find(".auth-passkey").trigger("click");
    await flushPromises();

    expect(wrapper.find(".auth-alert").exists()).toBeFalsy();
    expect(wrapper.find(".auth-passkey").text()).toBe("Sign in with a passkey");
    expect(mockPush).not.toHaveBeenCalled();
  });

  it("explains a failed passkey and falls back to the password", async () => {
    mockSignInWithPasskey.mockResolvedValue({
      status: "error",
      stage: "verify",
      errors: ["That passkey isn't linked to a vglist account."]
    });
    const wrapper = mount(LoginPage, mountOptions);

    await wrapper.find(".auth-passkey").trigger("click");
    await flushPromises();

    const alert = wrapper.find(".auth-alert");
    expect(alert.attributes("role")).toBe("alert");
    expect(alert.text()).toContain("That passkey didn't work.");
    expect(alert.text()).toContain("isn't linked to a vglist account");
    expect(mockPush).not.toHaveBeenCalled();
  });

  it("starts a background autofill request when the browser supports it", async () => {
    webauthn.autofill = true;
    mockSignInWithPasskey.mockReturnValue(new Promise(() => {}));
    mount(LoginPage, mountOptions);
    await flushPromises();

    expect(mockSignInWithPasskey).toHaveBeenCalledWith({ useBrowserAutofill: true });
  });

  it("signs in when a passkey is picked from autofill", async () => {
    vi.useFakeTimers();
    webauthn.autofill = true;
    mockSignInWithPasskey.mockResolvedValue({ status: "success", username: "connor" });
    mount(LoginPage, mountOptions);
    await flushPromises();
    vi.advanceTimersByTime(4000);
    vi.useRealTimers();

    expect(mockPush).toHaveBeenCalledWith("/");
  });

  describe("when the autofill request fails before the user picks a passkey", () => {
    afterEach(() => {
      vi.useRealTimers();
    });

    it("stays quiet and doesn't retry straight away when the options request fails", async () => {
      webauthn.autofill = true;
      mockSignInWithPasskey.mockResolvedValue({ status: "error", stage: "options", errors: ["Too many requests."] });
      const wrapper = mount(LoginPage, mountOptions);
      await flushPromises();
      await flushPromises();

      expect(mockSignInWithPasskey).toHaveBeenCalledTimes(1);
      expect(wrapper.find(".auth-alert").exists()).toBeFalsy();
    });

    it("retries a failed options request on the refresh timer", async () => {
      vi.useFakeTimers();
      webauthn.autofill = true;
      mockSignInWithPasskey.mockResolvedValue({ status: "error", stage: "options", errors: ["Server error."] });
      mount(LoginPage, mountOptions);
      await flushPromises();
      expect(mockSignInWithPasskey).toHaveBeenCalledTimes(1);

      await vi.advanceTimersByTimeAsync(4 * 60 * 1000);
      expect(mockSignInWithPasskey).toHaveBeenCalledTimes(2);
    });

    it("gives up on autofill when the browser call fails", async () => {
      vi.useFakeTimers();
      webauthn.autofill = true;
      mockSignInWithPasskey.mockResolvedValue({ status: "error", stage: "browser", errors: ["Browser error."] });
      const wrapper = mount(LoginPage, mountOptions);
      await flushPromises();

      await vi.advanceTimersByTimeAsync(10 * 60 * 1000);
      expect(mockSignInWithPasskey).toHaveBeenCalledTimes(1);
      expect(wrapper.find(".auth-alert").exists()).toBeFalsy();
    });
  });

  it("shows the alert and waits for another pick when the server rejects an autofilled passkey", async () => {
    webauthn.autofill = true;
    mockSignInWithPasskey
      .mockResolvedValueOnce({
        status: "error",
        stage: "verify",
        errors: ["That passkey isn't linked to a vglist account."]
      })
      .mockReturnValue(new Promise(() => {}));
    const wrapper = mount(LoginPage, mountOptions);
    await flushPromises();

    expect(wrapper.find(".auth-alert").text()).toContain("isn't linked to a vglist account");
    expect(mockSignInWithPasskey).toHaveBeenCalledTimes(2);
  });
});
