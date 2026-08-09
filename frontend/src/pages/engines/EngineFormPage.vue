<template>
  <ResourceForm
    v-model:name="name"
    v-model:wikidata-id="wikidataId"
    label="Engine"
    plural-label="engines"
    :is-editing="isEditing"
    :loading="isEditing && loading && !data"
    :submitting="submitting"
    :submit-error="submitError"
    :cancel-to="isEditing ? `/engines/${engineId}` : '/engines'"
    @submit="handleSubmit"
  />
</template>

<script setup lang="ts">
import { computed, ref, watch } from "vue";
import { useRoute, useRouter } from "vue-router";
import { useQuery, useMutation } from "@/composables/useGraphQL";
import { useSnackbar } from "@/composables/useSnackbar";
import { GET_ENGINE_FOR_EDIT } from "@/graphql/queries/resources";
import { CREATE_ENGINE, UPDATE_ENGINE } from "@/graphql/mutations/resources";
import { extractGqlError } from "@/utils/graphql-errors";
import type { GetEngineForEditQuery, CreateEngineMutation, UpdateEngineMutation } from "@/types/graphql";
import ResourceForm from "@/components/ResourceForm.vue";

// The edit route is used for typing because it is the superset of the two —
// on the "new" route there is simply no `id` param.
const route = useRoute("engineEdit");
const router = useRouter();
const { show: showSnackbar } = useSnackbar();

const isEditing = computed(() => !!route.params.id);
const engineId = computed(() => route.params.id);

const name = ref("");
const wikidataId = ref("");
const submitError = ref("");

const { data, loading, error } = useQuery<GetEngineForEditQuery>(GET_ENGINE_FOR_EDIT, {
  variables: () => ({ id: engineId.value }),
  enabled: () => isEditing.value
});

watch(
  () => data.value?.engine,
  (engine) => {
    if (!engine) return;
    name.value = engine.name;
    wikidataId.value = engine.wikidataId != null ? String(engine.wikidataId) : "";
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

// Redirect to 404 when editing an engine that doesn't exist.
watch([data, error, loading], () => {
  if (isEditing.value && !loading.value && (error.value || (data.value && !data.value.engine))) {
    router.replace({ name: "notFound" });
  }
});

const { mutate: createEngine, loading: creating } = useMutation<CreateEngineMutation>(CREATE_ENGINE);
const { mutate: updateEngine, loading: updating } = useMutation<UpdateEngineMutation>(UPDATE_ENGINE);
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
      const result = await updateEngine({
        engineId: engineId.value,
        name: trimmedName,
        wikidataId: trimmedWikidataId
      });
      const engine = result?.updateEngine?.engine;
      if (engine) {
        showSnackbar(`${engine.name} has been updated.`);
        router.push(`/engines/${engine.id}`);
      }
    } else {
      const result = await createEngine({ name: trimmedName, wikidataId: trimmedWikidataId });
      const engine = result?.createEngine?.engine;
      if (engine) {
        showSnackbar(`${engine.name} has been created.`);
        router.push(`/engines/${engine.id}`);
      }
    }
  } catch (e) {
    submitError.value = extractGqlError(e);
  }
}
</script>
