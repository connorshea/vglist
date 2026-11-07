import { describe, expect, it } from "vitest";
import { gamePrefillFromQuery, newGameLocation } from "./game-prefill";

describe("gamePrefillFromQuery", () => {
  it("reads the name and Steam App ID", () => {
    expect(gamePrefillFromQuery({ name: " Half-Life 2 ", steamAppId: "220" })).toEqual({
      name: "Half-Life 2",
      steamAppId: 220
    });
  });

  it("returns blanks when nothing is given", () => {
    expect(gamePrefillFromQuery({})).toEqual({ name: "", steamAppId: null });
  });

  it("ignores a Steam App ID that isn't a positive integer", () => {
    expect(gamePrefillFromQuery({ steamAppId: "22a" }).steamAppId).toBeNull();
    expect(gamePrefillFromQuery({ steamAppId: "-5" }).steamAppId).toBeNull();
    expect(gamePrefillFromQuery({ steamAppId: "0" }).steamAppId).toBeNull();
  });

  it("uses the first value of a repeated param", () => {
    expect(gamePrefillFromQuery({ name: ["Portal", "Portal 2"], steamAppId: ["400", null] })).toEqual({
      name: "Portal",
      steamAppId: 400
    });
  });

  it("caps the name at the form's max length", () => {
    expect(gamePrefillFromQuery({ name: "x".repeat(200) }).name).toHaveLength(120);
  });
});

describe("newGameLocation", () => {
  it("links to the new game form with both values", () => {
    expect(newGameLocation("Portal", 400)).toEqual({
      name: "gameNew",
      query: { name: "Portal", steamAppId: "400" }
    });
  });
});
