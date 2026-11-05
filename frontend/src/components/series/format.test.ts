import { describe, expect, it } from "vitest";
import { seriesMeta } from "./format";

describe("seriesMeta", () => {
  it("shows the game count and year span", () => {
    expect(seriesMeta(1284, 1986, 2024)).toBe("1,284 games · 1986–2024");
  });

  it("shows one year when the series spans a single year", () => {
    expect(seriesMeta(1, 2002, 2002)).toBe("1 game · 2002");
  });

  it("leaves the years out when no game has a release date", () => {
    expect(seriesMeta(3, null, null)).toBe("3 games");
  });

  it("says when a series has no games", () => {
    expect(seriesMeta(0, null, null)).toBe("No games yet");
  });
});
