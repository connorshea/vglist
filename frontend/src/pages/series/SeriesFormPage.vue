<template>
  <ResourceForm
    v-model:name="name"
    v-model:wikidata-id="wikidataId"
    label="Series"
    plural-label="series"
    :is-editing="isEditing"
    :loading="isEditing && loading"
    :submitting="submitting"
    :submit-error="submitError"
    :cancel-to="isEditing ? `/series/${seriesId}` : '/series'"
    @submit="handleSubmit"
  />
</template>

<script setup lang="ts">
import { computed, ref, watch } from "vue";
import { useRoute, useRouter } from "vue-router";
import { useQuery, useMutation } from "@/composables/useGraphQL";
import { useSnackbar } from "@/composables/useSnackbar";
import { GET_SERIES_FOR_EDIT } from "@/graphql/queries/resources";
import { CREATE_SERIES, UPDATE_SERIES } from "@/graphql/mutations/resources";
import { extractGqlError } from "@/utils/graphql-errors";
import type { GetSeriesForEditQuery, CreateSeriesMutation, UpdateSeriesMutation } from "@/types/graphql";
import ResourceForm from "@/components/ResourceForm.vue";

// The edit route is used for typing because it is the superset of the two —
// on the "new" route there is simply no `id` param.
const route = useRoute("seriesEdit");
const router = useRouter();
const { show: showSnackbar } = useSnackbar();

const isEditing = computed(() => !!route.params.id);
const seriesId = computed(() => route.params.id);

const name = ref("");
const wikidataId = ref("");
const submitError = ref("");

const { data, loading, error } = useQuery<GetSeriesForEditQuery>(GET_SERIES_FOR_EDIT, {
  variables: () => ({ id: seriesId.value }),
  enabled: () => isEditing.value
});

watch(
  () => data.value?.series,
  (series) => {
    if (!series) return;
    name.value = series.name;
    wikidataId.value = series.wikidataId != null ? String(series.wikidataId) : "";
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

// Redirect to 404 when editing a series that doesn't exist.
watch([data, error, loading], () => {
  if (isEditing.value && !loading.value && (error.value || (data.value && !data.value.series))) {
    router.replace({ name: "notFound" });
  }
});

const { mutate: createSeries, loading: creating } = useMutation<CreateSeriesMutation>(CREATE_SERIES);
const { mutate: updateSeries, loading: updating } = useMutation<UpdateSeriesMutation>(UPDATE_SERIES);
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
      const result = await updateSeries({
        seriesId: seriesId.value,
        name: trimmedName,
        wikidataId: trimmedWikidataId
      });
      const series = result?.updateSeries?.series;
      if (series) {
        showSnackbar(`${series.name} has been updated.`);
        router.push(`/series/${series.id}`);
      }
    } else {
      const result = await createSeries({ name: trimmedName, wikidataId: trimmedWikidataId });
      const series = result?.createSeries?.series;
      if (series) {
        showSnackbar(`${series.name} has been created.`);
        router.push(`/series/${series.id}`);
      }
    }
  } catch (e) {
    submitError.value = extractGqlError(e);
  }
}
</script>
