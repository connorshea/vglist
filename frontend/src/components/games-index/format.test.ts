import { describe, expect, it } from "vitest";
import {
  EMPTY_FILTERS,
  activeFiltersCount,
  countLabel,
  filterVariables,
  filtersFromQuery,
  filtersToQuery,
  gameSortFromSlug,
  libraryBadgeLabel,
  moreFiltersCount,
  ratingTier,
  releaseYear,
  tileMeta
} from "./format";

describe("releaseYear", () => {
  it("returns the year of an ISO date", () => {
    expect(releaseYear("2025-09-04")).toBe("2025");
  });

  it("returns null without a date", () => {
    expect(releaseYear(null)).toBeNull();
    expect(releaseYear("")).toBeNull();
  });
});

describe("countLabel", () => {
  it("formats and pluralizes", () => {
    expect(countLabel(1812, "owner")).toBe("1,812 owners");
    expect(countLabel(1, "owner")).toBe("1 owner");
  });
});

describe("tileMeta", () => {
  it("joins the year and owner count", () => {
    expect(tileMeta({ releaseDate: "2021-10-08", ownerCount: 612 })).toBe("2021 · 612 owners");
  });

  it("leaves out missing parts", () => {
    expect(tileMeta({ releaseDate: null, ownerCount: 3 })).toBe("3 owners");
    expect(tileMeta({ releaseDate: "2017-02-24", ownerCount: 0 })).toBe("2017");
    expect(tileMeta({ releaseDate: null, ownerCount: 0 })).toBeNull();
  });
});

describe("ratingTier", () => {
  it("bands ratings", () => {
    expect(ratingTier(93)).toBe("great");
    expect(ratingTier(90)).toBe("great");
    expect(ratingTier(89.9)).toBe("good");
    expect(ratingTier(75)).toBe("good");
    expect(ratingTier(60)).toBe("ok");
    expect(ratingTier(59)).toBe("low");
  });
});

describe("libraryBadgeLabel", () => {
  it("names the status, or falls back to In library", () => {
    expect(libraryBadgeLabel("IN_PROGRESS")).toBe("Playing");
    expect(libraryBadgeLabel(null)).toBe("In library");
  });
});

describe("gameSortFromSlug", () => {
  it("finds a sort by its slug", () => {
    expect(gameSortFromSlug("top").value).toBe("HIGHEST_AVG_RATING");
  });

  it("falls back to Popular", () => {
    expect(gameSortFromSlug("nope").value).toBe("MOST_OWNERS");
    expect(gameSortFromSlug(undefined).value).toBe("MOST_OWNERS");
  });
});

describe("filtersFromQuery / filtersToQuery", () => {
  it("round-trips filters through the URL", () => {
    const filters = {
      platform: "4",
      genre: "12",
      engine: "",
      fromYear: "2015",
      toYear: "2020",
      hideLibrary: true
    };
    expect(filtersFromQuery(filtersToQuery(filters))).toEqual(filters);
  });

  it("drops malformed values", () => {
    expect(filtersFromQuery({ platform: "abc", from: "1900", to: "20201", hide: "yes", genre: ["1"] })).toEqual(
      EMPTY_FILTERS
    );
  });

  it("leaves unset filters out of the URL", () => {
    expect(filtersToQuery(EMPTY_FILTERS)).toEqual({});
  });
});

describe("filterVariables", () => {
  it("maps filters to GraphQL arguments", () => {
    expect(filterVariables({ ...EMPTY_FILTERS, platform: "4", fromYear: "2015", hideLibrary: true })).toEqual({
      onPlatform: "4",
      byGenre: null,
      byEngine: null,
      fromYear: 2015,
      toYear: null,
      excludeLibrary: true
    });
  });
});

describe("moreFiltersCount", () => {
  it("counts the popover's filters, with a year range as one", () => {
    expect(moreFiltersCount(EMPTY_FILTERS)).toBe(0);
    expect(moreFiltersCount({ ...EMPTY_FILTERS, platform: "4", genre: "1", engine: "2" })).toBe(0);
    expect(moreFiltersCount({ ...EMPTY_FILTERS, fromYear: "2015", toYear: "2020", hideLibrary: true })).toBe(2);
  });
});

describe("activeFiltersCount", () => {
  it("counts every filter, with a year range as one", () => {
    expect(activeFiltersCount(EMPTY_FILTERS)).toBe(0);
    expect(
      activeFiltersCount({
        ...EMPTY_FILTERS,
        platform: "4",
        genre: "1",
        engine: "2",
        fromYear: "2015",
        toYear: "2020",
        hideLibrary: true
      })
    ).toBe(5);
  });
});
