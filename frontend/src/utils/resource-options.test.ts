import { describe, expect, it } from "vitest";
import { withSelectedOptions } from "./resource-options";

describe("withSelectedOptions", () => {
  const loaded = [
    { id: "1", name: "Unity" },
    { id: "2", name: "Unreal Engine" }
  ];

  it("returns the loaded options when nothing is selected", () => {
    expect(withSelectedOptions(loaded)).toEqual(loaded);
    expect(withSelectedOptions(loaded, [])).toEqual(loaded);
  });

  it("appends selections missing from the loaded options", () => {
    expect(withSelectedOptions(loaded, [{ id: "300", name: "Source" }])).toEqual([
      ...loaded,
      { id: "300", name: "Source" }
    ]);
  });

  it("doesn't duplicate selections that are already loaded", () => {
    expect(withSelectedOptions(loaded, [{ id: "2", name: "Unreal Engine" }])).toEqual(loaded);
  });

  it("merges several selection lists without duplicates", () => {
    const developers = [{ id: "300", name: "Valve" }];
    const publishers = [
      { id: "300", name: "Valve" },
      { id: "301", name: "Sierra" }
    ];
    expect(withSelectedOptions([], developers, publishers)).toEqual([
      { id: "300", name: "Valve" },
      { id: "301", name: "Sierra" }
    ]);
  });

  it("strips extra fields from selections", () => {
    const selected = [{ id: "300", name: "Source", gamesCount: 5 }];
    expect(withSelectedOptions([], selected)).toEqual([{ id: "300", name: "Source" }]);
  });
});
