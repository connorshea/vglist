import { ref } from "vue";

export interface SnackbarMessage {
  id: number;
  text: string;
  type: "success" | "error";
}

const messages = ref<SnackbarMessage[]>([]);
let nextId = 0;

export function useSnackbar() {
  function show(text: string, type: "success" | "error" = "success") {
    const id = nextId++;
    messages.value.push({ id, text, type });
    setTimeout(() => dismiss(id), 8000);
  }

  function dismiss(id: number) {
    messages.value = messages.value.filter((m) => m.id !== id);
  }

  return { messages, show, dismiss };
}
