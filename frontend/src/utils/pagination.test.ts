import { describe, expect, it } from "vitest";
import { offsetCursor, parsePageParam } from "./pagination";

describe("offsetCursor", () => {
  it.each([
    [2, "Mg"],
    [48, "NDg"],
    [96, "OTY"],
    [100, "MTAw"],
    [1234, "MTIzNA"]
  ])("encodes offset %i like graphql-ruby does", (offset, cursor) => {
    expect(offsetCursor(offset)).toBe(cursor);
  });

  it.each([0, -1, 1.5, Number.NaN])("returns null for %s, i.e. start at the beginning", (offset) => {
    expect(offsetCursor(offset)).toBeNull();
  });
});

describe("parsePageParam", () => {
  it.each([
    ["1", 1],
    ["2", 2],
    ["37", 37]
  ])("reads %s as page %i", (value, page) => {
    expect(parsePageParam(value)).toBe(page);
  });

  it.each([[undefined], [null], [""], ["0"], ["-2"], ["2.5"], ["abc"], ["02"], [["2", "3"]], ["99999999999999999999"]])(
    "treats %j as page 1",
    (value) => {
      expect(parsePageParam(value)).toBe(1);
    }
  );
});
