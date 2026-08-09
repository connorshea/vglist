<template>
  <ResourceForm
    v-model:name="name"
    v-model:wikidata-id="wikidataId"
    label="Company"
    plural-label="companies"
    :is-editing="isEditing"
    :loading="isEditing && loading && !data"
    :submitting="submitting"
    :submit-error="submitError"
    :cancel-to="isEditing ? `/companies/${companyId}` : '/companies'"
    @submit="handleSubmit"
  />
</template>

<script setup lang="ts">
import { computed, ref, watch } from "vue";
import { useRoute, useRouter } from "vue-router";
import { useQuery, useMutation } from "@/composables/useGraphQL";
import { useSnackbar } from "@/composables/useSnackbar";
import { GET_COMPANY_FOR_EDIT } from "@/graphql/queries/resources";
import { CREATE_COMPANY, UPDATE_COMPANY } from "@/graphql/mutations/resources";
import { extractGqlError } from "@/utils/graphql-errors";
import type { GetCompanyForEditQuery, CreateCompanyMutation, UpdateCompanyMutation } from "@/types/graphql";
import ResourceForm from "@/components/ResourceForm.vue";

// The edit route is used for typing because it is the superset of the two —
// on the "new" route there is simply no `id` param.
const route = useRoute("companyEdit");
const router = useRouter();
const { show: showSnackbar } = useSnackbar();

const isEditing = computed(() => !!route.params.id);
const companyId = computed(() => route.params.id);

const name = ref("");
const wikidataId = ref("");
const submitError = ref("");

const { data, loading, error } = useQuery<GetCompanyForEditQuery>(GET_COMPANY_FOR_EDIT, {
  variables: () => ({ id: companyId.value }),
  enabled: () => isEditing.value
});

watch(
  () => data.value?.company,
  (company) => {
    if (!company) return;
    name.value = company.name;
    wikidataId.value = company.wikidataId != null ? String(company.wikidataId) : "";
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

// Redirect to 404 when editing a company that doesn't exist.
watch([data, error, loading], () => {
  if (isEditing.value && !loading.value && (error.value || (data.value && !data.value.company))) {
    router.replace({ name: "notFound" });
  }
});

const { mutate: createCompany, loading: creating } = useMutation<CreateCompanyMutation>(CREATE_COMPANY);
const { mutate: updateCompany, loading: updating } = useMutation<UpdateCompanyMutation>(UPDATE_COMPANY);
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
      const result = await updateCompany({
        companyId: companyId.value,
        name: trimmedName,
        wikidataId: trimmedWikidataId
      });
      const company = result?.updateCompany?.company;
      if (company) {
        showSnackbar(`${company.name} has been updated.`);
        router.push(`/companies/${company.id}`);
      }
    } else {
      const result = await createCompany({ name: trimmedName, wikidataId: trimmedWikidataId });
      const company = result?.createCompany?.company;
      if (company) {
        showSnackbar(`${company.name} has been created.`);
        router.push(`/companies/${company.id}`);
      }
    }
  } catch (e) {
    submitError.value = extractGqlError(e);
  }
}
</script>
