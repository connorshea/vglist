<template>
  <div class="turnstile-widget">
    <div v-show="!loadError" ref="container" class="turnstile-container"></div>
    <p v-if="loadError" class="notification is-danger turnstile-error" role="alert">
      The human verification check couldn't load. If you use a content blocker, allow challenges.cloudflare.com and
      reload the page.
    </p>
  </div>
</template>

<script setup lang="ts">
import { onBeforeUnmount, onMounted, ref } from "vue";
import { loadTurnstile, type TurnstileApi } from "@/utils/turnstile";

// Renders a Cloudflare Turnstile challenge and exposes its token through
// v-model. The token is cleared when it expires or the challenge errors, and
// whenever the parent calls reset(): tokens are single-use, so reset after
// every submission that reached the server.
const props = withDefaults(defineProps<{ siteKey: string; action?: string }>(), { action: undefined });

const token = defineModel<string>({ default: "" });

const container = ref<HTMLElement | null>(null);
const loadError = ref(false);

let api: TurnstileApi | null = null;
let widgetId: string | undefined;
let unmounted = false;

onMounted(async () => {
  try {
    api = await loadTurnstile();
  } catch {
    loadError.value = true;
    return;
  }
  if (unmounted || !container.value) return;

  widgetId = api.render(container.value, {
    sitekey: props.siteKey,
    action: props.action,
    // The site follows the OS color scheme, and so does "auto".
    theme: "auto",
    // Fill the form's width like the inputs around it.
    size: "flexible",
    // We read the token from the callback, so skip the hidden input.
    "response-field": false,
    callback: (value) => {
      token.value = value;
    },
    "expired-callback": () => {
      token.value = "";
    },
    "error-callback": () => {
      token.value = "";
    }
  });
});

onBeforeUnmount(() => {
  unmounted = true;
  if (api && widgetId !== undefined) api.remove(widgetId);
});

function reset() {
  token.value = "";
  if (api && widgetId !== undefined) api.reset(widgetId);
}

defineExpose({ reset });
</script>

<style scoped>
.turnstile-widget {
  margin-bottom: 18px;
}

/* Reserve the widget's height so the submit button doesn't jump when the
   iframe appears. */
.turnstile-container {
  min-height: 65px;
}

.turnstile-error {
  font-size: 13px;
}
</style>
