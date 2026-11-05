import { describe, expect, it } from "vitest";
import { avatarColor, userInitials } from "./avatar";

describe("userInitials", () => {
  it("uses the first two letters, uppercased", () => {
    expect(userInitials("connor")).toBe("CO");
    expect(userInitials("x")).toBe("X");
  });
});

describe("avatarColor", () => {
  it("is stable for a username", () => {
    expect(avatarColor("connor")).toBe(avatarColor("connor"));
  });

  it("returns a hex colour", () => {
    expect(avatarColor("someone")).toMatch(/^#[0-9a-f]{6}$/);
  });
});
