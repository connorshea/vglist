import { computed } from "vue";
import { useRoute, useRouter } from "vue-router";
import { parsePageParam } from "@/utils/pagination";

/**
 * The current page of a paginated list, kept in the `page` query parameter so
 * that a reload or a shared link opens the same page and Back returns to the
 * previous one. Page 1 is left out of the URL.
 */
export function useUrlPage() {
  const route = useRoute();
  const router = useRouter();

  const page = computed(() => parsePageParam(route.query.page));

  function goToPage(target: number) {
    const query = { ...route.query };
    if (target <= 1) {
      delete query.page;
    } else {
      query.page = String(target);
    }
    // A push rather than a replace, so each page is its own history entry.
    void router.push({ query });
  }

  return { page, goToPage };
}
