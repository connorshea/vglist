<template>
  <ResourceForm
    v-model:name="name"
    label="Store"
    plural-label="stores"
    :with-wikidata-id="false"
    :is-editing="isEditing"
    :loading="isEditing && loading && !data"
    :submitting="submitting"
    :submit-error="submitError"
    :cancel-to="isEditing ? `/stores/${storeId}` : '/stores'"
    @submit="handleSubmit"
  />
</template>

<script setup lang="ts">
import { computed, ref, watch } from "vue";
import { useRoute, useRouter } from "vue-router";
import { useQuery, useMutation } from "@/composables/useGraphQL";
import { useSnackbar } from "@/composables/useSnackbar";
import { GET_STORE_FOR_EDIT } from "@/graphql/queries/resources";
import { CREATE_STORE, UPDATE_STORE } from "@/graphql/mutations/resources";
import { extractGqlError } from "@/utils/graphql-errors";
import type { GetStoreForEditQuery, CreateStoreMutation, UpdateStoreMutation } from "@/types/graphql";
import ResourceForm from "@/components/ResourceForm.vue";

// The edit route is used for typing because it is the superset of the two —
// on the "new" route there is simply no `id` param.
const route = useRoute("storeEdit");
const router = useRouter();
const { show: showSnackbar } = useSnackbar();

const isEditing = computed(() => !!route.params.id);
const storeId = computed(() => route.params.id);

const name = ref("");
const submitError = ref("");

const { data, loading, error } = useQuery<GetStoreForEditQuery>(GET_STORE_FOR_EDIT, {
  variables: () => ({ id: storeId.value }),
  enabled: () => isEditing.value
});

watch(
  () => data.value?.store,
  (store) => {
    if (!store) return;
    name.value = store.name;
  },
  { immediate: true }
);

// The "new" and "edit" routes resolve to this same component, so vue-router
// reuses the instance when navigating between them. Clear any values carried
// over from an edit when we land on "new".
watch(isEditing, (editing) => {
  if (editing) return;
  name.value = "";
  submitError.value = "";
});

// Redirect to 404 when editing a store that doesn't exist.
watch([data, error, loading], () => {
  if (isEditing.value && !loading.value && (error.value || (data.value && !data.value.store))) {
    router.replace({ name: "notFound" });
  }
});

const { mutate: createStore, loading: creating } = useMutation<CreateStoreMutation>(CREATE_STORE);
const { mutate: updateStore, loading: updating } = useMutation<UpdateStoreMutation>(UPDATE_STORE);
const submitting = computed(() => creating.value || updating.value);

async function handleSubmit() {
  submitError.value = "";

  const trimmedName = name.value.trim();

  if (!trimmedName) {
    submitError.value = "Name is required.";
    return;
  }

  try {
    if (isEditing.value) {
      const result = await updateStore({ storeId: storeId.value, name: trimmedName });
      const store = result?.updateStore?.store;
      if (store) {
        showSnackbar(`${store.name} has been updated.`);
        router.push(`/stores/${store.id}`);
      }
    } else {
      const result = await createStore({ name: trimmedName });
      const store = result?.createStore?.store;
      if (store) {
        showSnackbar(`${store.name} has been created.`);
        router.push(`/stores/${store.id}`);
      }
    }
  } catch (e) {
    submitError.value = extractGqlError(e);
  }
}
</script>
