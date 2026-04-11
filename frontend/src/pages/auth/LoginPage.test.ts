import { describe, it, expect, vi, beforeEach } from "vitest";
import { mount, flushPromises } from "@vue/test-utils";
import LoginPage from "./LoginPage.vue";

// ── Hoisted mocks ─────────────────────────────────────────────────

const { mockRoute, mockPush, mockSignIn } = vi.hoisted(() => ({
  mockRoute: { query: {} as Record<string, string> },
  mockPush: vi.fn<() => void>(),
  mockSignIn: vi.fn<(email: string, password: string) => Promise<{ success: boolean; errors: string[] }>>()
}));

vi.mock("vue-router", () => ({
  useRouter: () => ({ push: mockPush }),
  useRoute: () => mockRoute
}));

vi.mock("@/composables/useAuth", () => ({
  useAuth: () => ({
    signIn: mockSignIn
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
  });

  it("renders the form with email and password fields", () => {
    const wrapper = mount(LoginPage, mountOptions);

    expect(wrapper.find("h1").text()).toBe("Sign In");
    expect(wrapper.find("input[type='email']").exists()).toBeTruthy();
    expect(wrapper.find("input[type='password']").exists()).toBeTruthy();
    expect(wrapper.find("button[type='submit']").text()).toBe("Sign In");
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
