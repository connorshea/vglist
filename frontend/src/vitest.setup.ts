import { beforeEach } from "vitest";
import { clearQueryCache } from "@/graphql/query-cache";

// The query cache lives at module level, so without this a test would see
// results cached by the tests before it.
beforeEach(() => {
  clearQueryCache();
});
