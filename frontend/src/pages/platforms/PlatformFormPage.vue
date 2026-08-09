<template>
  <ResourceForm
    v-model:name="name"
    v-model:wikidata-id="wikidataId"
    label="Platform"
    plural-label="platforms"
    :is-editing="isEditing"
    :loading="isEditing && loading && !data"
    :submitting="submitting"
    :submit-error="submitError"
    :cancel-to="isEditing ? `/platforms/${platformId}` : '/platforms'"
    @submit="handleSubmit"
  />
</template>

<script setup lang="ts">
import { computed, ref, watch } from "vue";
import { useRoute, useRouter } from "vue-router";
import { useQuery, useMutation } from "@/composables/useGraphQL";
import { useSnackbar } from "@/composables/useSnackbar";
import { GET_PLATFORM_FOR_EDIT } from "@/graphql/queries/resources";
import { CREATE_PLATFORM, UPDATE_PLATFORM } from "@/graphql/mutations/resources";
import { extractGqlError } from "@/utils/graphql-errors";
import type { GetPlatformForEditQuery, CreatePlatformMutation, UpdatePlatformMutation } from "@/types/graphql";
import ResourceForm from "@/components/ResourceForm.vue";

// The edit route is used for typing because it is the superset of the two —
// on the "new" route there is simply no `id` param.
const route = useRoute("platformEdit");
const router = useRouter();
const { show: showSnackbar } = useSnackbar();

const isEditing = computed(() => !!route.params.id);
const platformId = computed(() => route.params.id);

const name = ref("");
const wikidataId = ref("");
const submitError = ref("");

const { data, loading, error } = useQuery<GetPlatformForEditQuery>(GET_PLATFORM_FOR_EDIT, {
  variables: () => ({ id: platformId.value }),
  enabled: () => isEditing.value
});

watch(
  () => data.value?.platform,
  (platform) => {
    if (!platform) return;
    name.value = platform.name;
    wikidataId.value = platform.wikidataId != null ? String(platform.wikidataId) : "";
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

// Redirect to 404 when editing a platform that doesn't exist.
watch([data, error, loading], () => {
  if (isEditing.value && !loading.value && (error.value || (data.value && !data.value.platform))) {
    router.replace({ name: "notFound" });
  }
});

const { mutate: createPlatform, loading: creating } = useMutation<CreatePlatformMutation>(CREATE_PLATFORM);
const { mutate: updatePlatform, loading: updating } = useMutation<UpdatePlatformMutation>(UPDATE_PLATFORM);
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
      const result = await updatePlatform({
        platformId: platformId.value,
        name: trimmedName,
        wikidataId: trimmedWikidataId
      });
      const platform = result?.updatePlatform?.platform;
      if (platform) {
        showSnackbar(`${platform.name} has been updated.`);
        router.push(`/platforms/${platform.id}`);
      }
    } else {
      const result = await createPlatform({ name: trimmedName, wikidataId: trimmedWikidataId });
      const platform = result?.createPlatform?.platform;
      if (platform) {
        showSnackbar(`${platform.name} has been created.`);
        router.push(`/platforms/${platform.id}`);
      }
    }
  } catch (e) {
    submitError.value = extractGqlError(e);
  }
}
</script>
