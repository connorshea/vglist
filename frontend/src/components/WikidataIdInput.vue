<template>
  <input
    :value="model"
    class="input"
    type="text"
    placeholder="e.g. Q12345"
    autocomplete="off"
    @input="onInput"
    @change="onChange"
  />
</template>

<script setup lang="ts">
import { normalizeWikidataId } from "@/utils/wikidata";

// A text input for a Wikidata item ID that accepts "123", "Q123" or a
// Wikidata item URL and normalizes it to the numeric ID. Attributes such as
// `id`, `required` and `aria-describedby` fall through to the <input>.
const model = defineModel<string>({ default: "" });

// Pasted values are normalized right away. Typed values are normalized when
// the field loses focus, so the value doesn't change under the cursor while
// someone is still typing "Q123".
function onInput(event: Event) {
  const target = event.target as HTMLInputElement;
  const pasted = event instanceof InputEvent && event.inputType === "insertFromPaste";
  update(target, pasted ? normalizeWikidataId(target.value) : target.value);
}

function onChange(event: Event) {
  const target = event.target as HTMLInputElement;
  const normalized = normalizeWikidataId(target.value);
  if (normalized !== target.value) {
    update(target, normalized);
  }
}

function update(target: HTMLInputElement, value: string) {
  // Set the DOM value directly too: if the normalized value matches the
  // current model, Vue won't re-render and the raw input would stay visible.
  if (target.value !== value) {
    target.value = value;
  }
  model.value = value;
}
</script>
