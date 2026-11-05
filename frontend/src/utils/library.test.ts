import { describe, expect, it } from "vitest";
import {
  formatHours,
  formatStartDate,
  gameInitials,
  isLibrarySort,
  isLibraryStatus,
  isLibraryStatusFilter,
  parseIdList,
  parseRating,
  ratingTier
} from "./library";

describe("ratingTier", () => {
  it("buckets ratings into the design system's tiers", () => {
    expect(ratingTier(97)).toBe("r-great");
    expect(ratingTier(90)).toBe("r-great");
    expect(ratingTier(89)).toBe("r-good");
    expect(ratingTier(75)).toBe("r-good");
    expect(ratingTier(60)).toBe("r-ok");
    expect(ratingTier(59)).toBe("r-low");
    expect(ratingTier(0)).toBe("r-low");
  });
});

describe("gameInitials", () => {
  it("takes up to three initials, splitting on colons too", () => {
    expect(gameInitials("Hollow Knight: Silksong")).toBe("HKS");
    expect(gameInitials("Return of the Obra Dinn")).toBe("ROT");
    expect(gameInitials("celeste")).toBe("C");
  });
});

describe("formatHours", () => {
  it("formats whole and fractional hours", () => {
    expect(formatHours(31)).toBe("31h");
    expect(formatHours(22.5)).toBe("22.5h");
    expect(formatHours(11.25)).toBe("11.3h");
  });

  it("returns null when there are no hours", () => {
    expect(formatHours(null)).toBeNull();
    expect(formatHours(undefined)).toBeNull();
    expect(formatHours(0)).toBeNull();
  });
});

describe("formatStartDate", () => {
  const now = new Date("2026-11-05T12:00:00Z");

  it("leaves out the year for dates this year", () => {
    expect(formatStartDate("2026-09-04", now)).toBe("Sep 4");
  });

  it("includes the year for older dates", () => {
    expect(formatStartDate("2024-01-31", now)).toBe("Jan 31, 2024");
  });
});

describe("query string parsing", () => {
  it("parses comma-separated ID lists, dropping junk", () => {
    expect(parseIdList("1,22,abc,,3")).toEqual(["1", "22", "3"]);
    expect(parseIdList(["4", "5,6"])).toEqual(["4", "5", "6"]);
    expect(parseIdList(undefined)).toEqual([]);
  });

  it("parses ratings between 0 and 100", () => {
    expect(parseRating("60")).toBe(60);
    expect(parseRating("0")).toBe(0);
    expect(parseRating("101")).toBeNull();
    expect(parseRating("-1")).toBeNull();
    expect(parseRating(undefined)).toBeNull();
  });

  it("recognises statuses and sorts", () => {
    expect(isLibraryStatus("PAUSED")).toBeTruthy();
    expect(isLibraryStatus("paused")).toBeFalsy();
    expect(isLibrarySort("GAME_NAME")).toBeTruthy();
    expect(isLibrarySort("NEWEST")).toBeFalsy();
  });
});

describe("isLibraryStatusFilter", () => {
  it("accepts the statuses and NONE, but nothing else", () => {
    expect(isLibraryStatusFilter("COMPLETED")).toBeTruthy();
    expect(isLibraryStatusFilter("NONE")).toBeTruthy();
    expect(isLibraryStatus("NONE")).toBeFalsy();
    expect(isLibraryStatusFilter("none")).toBeFalsy();
    expect(isLibraryStatusFilter(undefined)).toBeFalsy();
  });
});
