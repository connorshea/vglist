import { describe, expect, it } from "vitest";
import { isValidWikidataId, normalizeWikidataId } from "./wikidata";

describe("normalizeWikidataId", () => {
  it.each([
    ["123", "123"],
    ["  123  ", "123"],
    ["Q123", "123"],
    ["q123", "123"],
    [" Q123 ", "123"],
    ["https://www.wikidata.org/wiki/Q123", "123"],
    ["http://www.wikidata.org/wiki/Q123", "123"],
    ["https://wikidata.org/wiki/Q123", "123"],
    ["https://m.wikidata.org/wiki/Q123", "123"],
    ["www.wikidata.org/wiki/Q123", "123"],
    ["https://www.wikidata.org/wiki/Q123/", "123"],
    ["https://www.wikidata.org/wiki/Q123?uselang=en", "123"],
    ["https://www.wikidata.org/wiki/Q123#P31", "123"],
    ["https://www.wikidata.org/entity/Q123", "123"],
    ["http://www.wikidata.org/entity/Q123", "123"],
    ["https://www.wikidata.org/wiki/Special:EntityPage/Q123", "123"]
  ])("normalizes %j to %j", (input, expected) => {
    expect(normalizeWikidataId(input)).toBe(expected);
  });

  it.each([
    ["", ""],
    ["  ", ""],
    ["Q", "Q"],
    ["abc", "abc"],
    ["P123", "P123"],
    ["Q12a", "Q12a"],
    ["https://www.wikidata.org/wiki/P123", "https://www.wikidata.org/wiki/P123"],
    ["https://example.com/wiki/Q123", "https://example.com/wiki/Q123"],
    ["https://notwikidata.org/wiki/Q123", "https://notwikidata.org/wiki/Q123"]
  ])("leaves unrecognized input %j as %j", (input, expected) => {
    expect(normalizeWikidataId(input)).toBe(expected);
  });
});

describe("isValidWikidataId", () => {
  it("accepts positive whole numbers", () => {
    expect(isValidWikidataId("1")).toBeTruthy();
    expect(isValidWikidataId("1050023")).toBeTruthy();
  });

  it("rejects anything else", () => {
    expect(isValidWikidataId("")).toBeFalsy();
    expect(isValidWikidataId("0")).toBeFalsy();
    expect(isValidWikidataId("Q123")).toBeFalsy();
    expect(isValidWikidataId("-1")).toBeFalsy();
    expect(isValidWikidataId("1.5")).toBeFalsy();
  });
});
