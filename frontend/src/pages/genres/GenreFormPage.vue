<template>
  <ResourceForm
    v-model:name="name"
    v-model:wikidata-id="wikidataId"
    label="Genre"
    plural-label="genres"
    :is-editing="isEditing"
    :loading="isEditing && loading && !data"
    :submitting="submitting"
    :submit-error="submitError"
    :cancel-to="isEditing ? `/genres/${genreId}` : '/genres'"
    @submit="handleSubmit"
  />
</template>

<script setup lang="ts">
import { computed, ref, watch } from "vue";
import { useRoute, useRouter } from "vue-router";
import { useQuery, useMutation } from "@/composables/useGraphQL";
import { useSnackbar } from "@/composables/useSnackbar";
import { GET_GENRE_FOR_EDIT } from "@/graphql/queries/resources";
import { CREATE_GENRE, UPDATE_GENRE } from "@/graphql/mutations/resources";
import { extractGqlError } from "@/utils/graphql-errors";
import type { GetGenreForEditQuery, CreateGenreMutation, UpdateGenreMutation } from "@/types/graphql";
import ResourceForm from "@/components/ResourceForm.vue";

// The edit route is used for typing because it is the superset of the two —
// on the "new" route there is simply no `id` param.
const route = useRoute("genreEdit");
const router = useRouter();
const { show: showSnackbar } = useSnackbar();

const isEditing = computed(() => !!route.params.id);
const genreId = computed(() => route.params.id);

const name = ref("");
const wikidataId = ref("");
const submitError = ref("");

const { data, loading, error } = useQuery<GetGenreForEditQuery>(GET_GENRE_FOR_EDIT, {
  variables: () => ({ id: genreId.value }),
  enabled: () => isEditing.value
});

watch(
  () => data.value?.genre,
  (genre) => {
    if (!genre) return;
    name.value = genre.name;
    wikidataId.value = genre.wikidataId != null ? String(genre.wikidataId) : "";
  },
  { immediate: true }
);

// The "new" and "edit" routes resolve to this same component, so vue-router
// reuses the instance when navigating between them. Clear any values carried
// over from an edit when we land on "new".
watch(isEditing, (editing) => {
  if (editing) return;
  name.value = "";
  wikidataId.value = "";
  submitError.value = "";
});

// Redirect to 404 when editing a genre that doesn't exist.
watch([data, error, loading], () => {
  if (isEditing.value && !loading.value && (error.value || (data.value && !data.value.genre))) {
    router.replace({ name: "notFound" });
  }
});

const { mutate: createGenre, loading: creating } = useMutation<CreateGenreMutation>(CREATE_GENRE);
const { mutate: updateGenre, loading: updating } = useMutation<UpdateGenreMutation>(UPDATE_GENRE);
const submitting = computed(() => creating.value || updating.value);

async function handleSubmit() {
  submitError.value = "";

  const trimmedName = name.value.trim();
  const trimmedWikidataId = wikidataId.value.trim();

  if (!trimmedName) {
    submitError.value = "Name is required.";
    return;
  }

  if (!/^\d+$/.test(trimmedWikidataId) || Number(trimmedWikidataId) <= 0) {
    submitError.value = "Wikidata ID must be a positive number.";
    return;
  }

  try {
    if (isEditing.value) {
      const result = await updateGenre({
        genreId: genreId.value,
        name: trimmedName,
        wikidataId: trimmedWikidataId
      });
      const genre = result?.updateGenre?.genre;
      if (genre) {
        showSnackbar(`${genre.name} has been updated.`);
        router.push(`/genres/${genre.id}`);
      }
    } else {
      const result = await createGenre({ name: trimmedName, wikidataId: trimmedWikidataId });
      const genre = result?.createGenre?.genre;
      if (genre) {
        showSnackbar(`${genre.name} has been created.`);
        router.push(`/genres/${genre.id}`);
      }
    }
  } catch (e) {
    submitError.value = extractGqlError(e);
  }
}
</script>
