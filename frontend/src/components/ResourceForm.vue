<template>
  <section class="section">
    <div class="columns is-centered">
      <div class="column is-6">
        <div v-if="!authStore.isModerator" class="notification is-warning">
          <p>You must be a moderator or admin to create or edit {{ pluralLabel }}.</p>
        </div>

        <template v-else>
          <h1 class="title">{{ isEditing ? `Edit ${label}` : `New ${label}` }}</h1>

          <div v-if="loading" class="has-text-centered py-5">
            <p>Loading {{ lowerLabel }}...</p>
          </div>

          <form v-else @submit.prevent="emit('submit')">
            <div class="field">
              <label class="label" :for="`${slug}-name`">Name <span class="has-text-danger">*</span></label>
              <div class="control">
                <input
                  :id="`${slug}-name`"
                  :value="name"
                  class="input"
                  type="text"
                  required
                  maxlength="120"
                  :placeholder="`${label} name`"
                  @input="emit('update:name', ($event.target as HTMLInputElement).value)"
                />
              </div>
            </div>

            <div v-if="withWikidataId" class="field">
              <label class="label" :for="`${slug}-wikidata-id`">
                Wikidata ID <span class="has-text-danger">*</span>
              </label>
              <div class="control">
                <WikidataIdInput
                  :id="`${slug}-wikidata-id`"
                  :model-value="wikidataId"
                  required
                  :aria-describedby="`${slug}-wikidata-id-help`"
                  @update:model-value="emit('update:wikidataId', $event)"
                />
              </div>
              <p :id="`${slug}-wikidata-id-help`" class="help">
                The Wikidata item ID, like "Q12345". You can also paste the item's Wikidata URL.
              </p>
            </div>

            <div v-if="submitError" class="notification is-danger mt-4">
              <p>{{ submitError }}</p>
            </div>

            <div class="field is-grouped mt-5">
              <div class="control">
                <button
                  type="submit"
                  class="button is-primary"
                  :class="{ 'is-loading': submitting }"
                  :disabled="submitting"
                >
                  {{ isEditing ? "Save Changes" : `Create ${label}` }}
                </button>
              </div>
              <div class="control">
                <router-link :to="cancelTo" class="button is-light">Cancel</router-link>
              </div>
            </div>
          </form>
        </template>
      </div>
    </div>
  </section>
</template>

<script setup lang="ts">
import { computed } from "vue";
import { useAuthStore } from "@/stores/auth";
import WikidataIdInput from "@/components/WikidataIdInput.vue";

const props = withDefaults(
  defineProps<{
    name: string;
    wikidataId?: string;
    /** Singular, capitalized resource name, e.g. "Platform". */
    label: string;
    /** Plural, lowercase resource name, e.g. "platforms". */
    pluralLabel: string;
    isEditing: boolean;
    /** Whether this resource has a Wikidata ID. Stores, for example, don't. */
    withWikidataId?: boolean;
    /** True while an existing record is being fetched for editing. */
    loading?: boolean;
    submitting?: boolean;
    submitError?: string;
    /** Where the Cancel button links to. */
    cancelTo: string;
  }>(),
  {
    wikidataId: "",
    withWikidataId: true,
    loading: false,
    submitting: false,
    submitError: ""
  }
);

const emit = defineEmits<{
  "update:name": [value: string];
  "update:wikidataId": [value: string];
  submit: [];
}>();

const authStore = useAuthStore();

const lowerLabel = computed(() => props.label.toLowerCase());
// Used to keep the `for`/`id` pairs unique and readable, e.g. "platform-name".
const slug = computed(() => props.label.toLowerCase().replace(/\s+/g, "-"));
</script>
