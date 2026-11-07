import { describe, it, expect, vi, beforeEach, afterEach } from "vitest";
import { mount, flushPromises } from "@vue/test-utils";
import SignupPage from "./SignupPage.vue";
import type { TurnstileRenderOptions } from "@/utils/turnstile";

// ── Hoisted mocks ─────────────────────────────────────────────────

const { mockSignUp } = vi.hoisted(() => ({
  mockSignUp:
    vi.fn<
      (
        username: string,
        email: string,
        password: string,
        passwordConfirmation: string,
        turnstileToken?: string
      ) => Promise<{ success: boolean; errors: string[] }>
    >()
}));

vi.mock("vue-router", () => ({
  useRouter: () => ({ push: vi.fn<() => void>() })
}));

vi.mock("@/composables/useAuth", () => ({
  useAuth: () => ({
    signUp: mockSignUp
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

describe("SignupPage", () => {
  beforeEach(() => {
    mockSignUp.mockReset();
  });

  it("renders the form with all required fields", () => {
    const wrapper = mount(SignupPage, mountOptions);

    expect(wrapper.find("h1").text()).toBe("Create an account");
    expect(wrapper.find("input[type='text']").exists()).toBeTruthy();
    expect(wrapper.find("input[type='email']").exists()).toBeTruthy();
    expect(wrapper.findAll("input[type='password']")).toHaveLength(2);
    expect(wrapper.find("button[type='submit']").text()).toBe("Create account");
  });

  it("calls signUp with all fields on submit", async () => {
    mockSignUp.mockResolvedValue({ success: true, errors: [] });
    const wrapper = mount(SignupPage, mountOptions);

    await wrapper.find("input[type='text']").setValue("testuser");
    await wrapper.find("input[type='email']").setValue("test@example.com");
    const passwordInputs = wrapper.findAll("input[type='password']");
    await passwordInputs[0].setValue("password123");
    await passwordInputs[1].setValue("password123");
    await wrapper.find("form").trigger("submit");
    await flushPromises();

    expect(mockSignUp).toHaveBeenCalledWith("testuser", "test@example.com", "password123", "password123", undefined);
  });

  it("shows success message and hides the form on success", async () => {
    mockSignUp.mockResolvedValue({ success: true, errors: [] });
    const wrapper = mount(SignupPage, mountOptions);

    await wrapper.find("input[type='text']").setValue("testuser");
    await wrapper.find("input[type='email']").setValue("test@example.com");
    const passwordInputs = wrapper.findAll("input[type='password']");
    await passwordInputs[0].setValue("password123");
    await passwordInputs[1].setValue("password123");
    await wrapper.find("form").trigger("submit");
    await flushPromises();

    expect(wrapper.find(".notification.is-success").text()).toContain("Account created successfully");
    expect(wrapper.find("form").exists()).toBeFalsy();
  });

  it("shows errors on failed sign-up", async () => {
    mockSignUp.mockResolvedValue({ success: false, errors: ["Email has already been taken."] });
    const wrapper = mount(SignupPage, mountOptions);

    await wrapper.find("input[type='text']").setValue("testuser");
    await wrapper.find("input[type='email']").setValue("taken@example.com");
    const passwordInputs = wrapper.findAll("input[type='password']");
    await passwordInputs[0].setValue("password123");
    await passwordInputs[1].setValue("password123");
    await wrapper.find("form").trigger("submit");
    await flushPromises();

    expect(wrapper.find(".notification.is-danger").text()).toContain("Email has already been taken.");
    expect(wrapper.find("form").exists()).toBeTruthy();
  });

  it("shows loading state while submitting", async () => {
    mockSignUp.mockReturnValue(new Promise<{ success: boolean; errors: string[] }>(() => {}));
    const wrapper = mount(SignupPage, mountOptions);

    await wrapper.find("input[type='text']").setValue("testuser");
    await wrapper.find("input[type='email']").setValue("test@example.com");
    const passwordInputs = wrapper.findAll("input[type='password']");
    await passwordInputs[0].setValue("password123");
    await passwordInputs[1].setValue("password123");
    await wrapper.find("form").trigger("submit");

    expect(wrapper.find("button[type='submit']").text()).toBe("Creating account...");
    expect(wrapper.find("button[type='submit']").attributes("disabled")).toBeDefined();
  });

  describe("with Turnstile enabled", () => {
    let solve: (token: string) => void;
    const render = vi.fn<(container: HTMLElement, options: TurnstileRenderOptions) => string>();
    const reset = vi.fn<(widgetId?: string) => void>();
    const remove = vi.fn<(widgetId?: string) => void>();

    async function fillAndSubmit(wrapper: ReturnType<typeof mount>) {
      await wrapper.find("input[type='text']").setValue("testuser");
      await wrapper.find("input[type='email']").setValue("test@example.com");
      const passwordInputs = wrapper.findAll("input[type='password']");
      await passwordInputs[0].setValue("password123");
      await passwordInputs[1].setValue("password123");
      await wrapper.find("form").trigger("submit");
      await flushPromises();
    }

    beforeEach(() => {
      vi.stubEnv("VITE_TURNSTILE_SITE_KEY", "1x00000000000000000000AA");
      render.mockReset().mockImplementation((_container, options) => {
        solve = (token) => options.callback?.(token);
        return "widget-1";
      });
      reset.mockReset();
      remove.mockReset();
      window.turnstile = { render, reset, remove };
    });

    afterEach(() => {
      vi.unstubAllEnvs();
      delete window.turnstile;
    });

    it("renders the challenge with the site key", async () => {
      mount(SignupPage, mountOptions);
      await flushPromises();

      expect(render).toHaveBeenCalledOnce();
      expect(render.mock.calls[0][1]).toMatchObject({ sitekey: "1x00000000000000000000AA", action: "signup" });
    });

    it("does not submit before the challenge is solved", async () => {
      const wrapper = mount(SignupPage, mountOptions);
      await flushPromises();

      await fillAndSubmit(wrapper);

      expect(mockSignUp).not.toHaveBeenCalled();
      expect(wrapper.find(".notification.is-danger").text()).toContain("human verification");
    });

    it("sends the token, and resets the challenge after a failed sign-up", async () => {
      mockSignUp.mockResolvedValue({ success: false, errors: ["Email has already been taken."] });
      const wrapper = mount(SignupPage, mountOptions);
      await flushPromises();
      solve("token-123");

      await fillAndSubmit(wrapper);

      expect(mockSignUp).toHaveBeenCalledWith(
        "testuser",
        "test@example.com",
        "password123",
        "password123",
        "token-123"
      );
      expect(reset).toHaveBeenCalledWith("widget-1");

      // The spent token is gone, so another submit waits for a new one.
      mockSignUp.mockClear();
      await wrapper.find("form").trigger("submit");
      await flushPromises();
      expect(mockSignUp).not.toHaveBeenCalled();
    });

    it("removes the widget on unmount", async () => {
      const wrapper = mount(SignupPage, mountOptions);
      await flushPromises();

      wrapper.unmount();

      expect(remove).toHaveBeenCalledWith("widget-1");
    });
  });
});
