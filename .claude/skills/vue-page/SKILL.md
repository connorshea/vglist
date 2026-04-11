---
name: vue-page
description: Scaffold a Vue 3 page component with GraphQL integration, following vglist frontend conventions.
---

# Vue Page Scaffolder

Generate a Vue 3 page component with GraphQL data fetching, following vglist patterns.

## Input

The user specifies:
- The entity/resource name (e.g., "Publisher")
- The page type: **list**, **show**, or **form**

Read the relevant GraphQL type from `app/graphql/types/<entity>_type.rb` and any existing query/mutation operations in `frontend/src/graphql/` to understand available fields.

## Page types

### List page (`<Entity>ListPage.vue`)

Location: `frontend/src/pages/<entities>/<Entity>ListPage.vue`

```vue
<template>
  <div>
    <section class="section">
      <div class="container">
        <h1 class="title"><Entities></h1>

        <div v-if="loading && !data" class="has-text-centered py-6">
          <p>Loading...</p>
        </div>

        <div v-if="error" class="notification is-danger">
          <p>Failed to load <entities>: {{ error.message }}</p>
        </div>

        <div v-if="<entities>">
          <!-- List content here -->
        </div>

        <!-- Cursor-based pagination controls -->
      </div>
    </section>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, watch } from "vue";
import { useQuery } from "@/composables/useGraphQL";
import { GET_<ENTITIES> } from "@/graphql/queries/resources";
import type { Get<Entities>Query } from "@/types/graphql";

const PAGE_SIZE = 25;
const currentPage = ref(1);
const pageCursors = ref<(string | null)[]>([null]);

const { data, loading, error } = useQuery<Get<Entities>Query>(GET_<ENTITIES>, {
  variables: () => ({
    first: PAGE_SIZE,
    after: pageCursors.value[currentPage.value - 1],
  }),
});

const <entities> = computed(() => data.value?.<entities>?.nodes ?? []);
const hasNextPage = computed(() => data.value?.<entities>?.pageInfo.hasNextPage ?? false);

watch(data, (val) => {
  if (val?.<entities>?.pageInfo.endCursor) {
    pageCursors.value[currentPage.value] = val.<entities>.pageInfo.endCursor;
  }
});
</script>
```

### Show page (`<Entity>ShowPage.vue`)

Location: `frontend/src/pages/<entities>/<Entity>ShowPage.vue`

```vue
<template>
  <div>
    <div v-if="loading && !data" class="has-text-centered py-6">
      <p>Loading <entity>...</p>
    </div>

    <div v-if="error" class="notification is-danger">
      <p>Failed to load <entity>: {{ error.message }}</p>
    </div>

    <div v-if="<entity>">
      <!-- Show content here -->
    </div>
  </div>
</template>

<script setup lang="ts">
import { computed, watch } from "vue";
import { useRoute, useRouter } from "vue-router/auto";
import { useQuery } from "@/composables/useGraphQL";
import { GET_<ENTITY> } from "@/graphql/queries/resources";
import type { Get<Entity>Query } from "@/types/graphql";

const route = useRoute("<entity>");
const router = useRouter();

const { data, loading, error } = useQuery<Get<Entity>Query>(GET_<ENTITY>, {
  variables: { id: route.params.id },
});

const <entity> = computed(() => data.value?.<entity> ?? null);

// Redirect to 404 if entity not found
watch([data, error, loading], () => {
  if (!loading.value && (error.value || (data.value && !data.value.<entity>))) {
    router.replace({ name: "notFound" });
  }
});
</script>
```

### Form page (`<Entity>FormPage.vue`)

Location: `frontend/src/pages/<entities>/<Entity>FormPage.vue`

```vue
<script setup lang="ts">
import { computed, reactive, ref, watch } from "vue";
import { useRoute, useRouter } from "vue-router/auto";
import { useQuery, useMutation } from "@/composables/useGraphQL";
import { GET_<ENTITY> } from "@/graphql/queries/resources";
import { CREATE_<ENTITY>, UPDATE_<ENTITY> } from "@/graphql/mutations/<entities>";
import type { ... } from "@/types/graphql";

const route = useRoute();
const router = useRouter();

const isEditing = computed(() => !!route.params.id);

// Fetch existing data when editing
const { data: entityData, loading: entityLoading } = useQuery<...>(GET_<ENTITY>, {
  variables: () => ({ id: route.params.id as string }),
  enabled: () => isEditing.value,
});

// Form state
const form = reactive({
  name: "",
  // ... other fields
});

const submitError = ref("");

// Populate form when editing
watch(() => entityData.value?.<entity>, (<entity>) => {
  if (!<entity>) return;
  form.name = <entity>.name;
  // ... populate other fields
});

// Mutations
const { mutate: createEntity, loading: creating } = useMutation(CREATE_<ENTITY>);
const { mutate: updateEntity, loading: updating } = useMutation(UPDATE_<ENTITY>);

async function handleSubmit() {
  submitError.value = "";
  if (!form.name.trim()) {
    submitError.value = "Name is required.";
    return;
  }
  try {
    if (isEditing.value) {
      await updateEntity({ <entity>Id: route.params.id, ...form });
    } else {
      const result = await createEntity({ ...form });
      // Navigate to new entity
    }
  } catch (e: unknown) {
    submitError.value = e instanceof Error ? e.message : "An error occurred.";
  }
}
</script>
```

## GraphQL operation files

If the required query or mutation doesn't exist yet, also create it:

- **Queries**: `frontend/src/graphql/queries/resources.ts` (add to existing file for standard entities)
- **Mutations**: `frontend/src/graphql/mutations/<entities>.ts` (new file per entity domain)

Use `gql` from `graphql-tag`:

```typescript
import gql from "graphql-tag";

export const GET_<ENTITY> = gql`
  query Get<Entity>($id: ID!) {
    <entity>(id: $id) {
      id
      name
      wikidataId
      createdAt
      updatedAt
    }
  }
`;
```

## Router registration

Add routes to `frontend/src/router/index.ts`:

```typescript
{
  path: "/<entities>",
  name: "<entities>",
  component: () => import("@/pages/<entities>/<Entity>ListPage.vue"),
},
{
  path: "/<entities>/:id",
  name: "<entity>",
  component: () => import("@/pages/<entities>/<Entity>ShowPage.vue"),
},
{
  path: "/<entities>/new",
  name: "<entity>New",
  component: () => import("@/pages/<entities>/<Entity>FormPage.vue"),
  meta: { requiresAuth: true, requiresModerator: true },
},
{
  path: "/<entities>/:id/edit",
  name: "<entity>Edit",
  component: () => import("@/pages/<entities>/<Entity>FormPage.vue"),
  meta: { requiresAuth: true, requiresModerator: true },
},
```

## After generating

Remind the user to:
1. Run `cd frontend && yarn codegen` if new GraphQL operations were added.
2. Run `cd frontend && yarn typecheck` to verify types.
3. Run `cd frontend && yarn fmt` to format new files.

## Rules

- Always use `<script setup lang="ts">` — never Options API.
- No `any` types — use generated types from `@/types/graphql`.
- Use Bulma CSS classes for layout (`section`, `container`, `title`, `notification`, `columns`, `column`).
- Use Lucide icons via `lucide-vue-next` — never custom SVG components.
- Include loading and error states in every page template.
- Use `useRoute` and `useRouter` from `vue-router/auto`.
- Use semantic HTML and include ARIA attributes where appropriate (e.g., `aria-label` on icon buttons, `role` on dynamic regions).
- Variables passed to `useQuery` should be a getter function `() => ({...})` when they depend on reactive state, or a plain object when static.
- Use `computed()` to derive display values from query data, not direct template access to `data.value`.
