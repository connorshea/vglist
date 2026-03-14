import { ref } from "vue";

const isOpen = ref(false);

export function useSearchOverlay() {
  function open() {
    isOpen.value = true;
  }

  function close() {
    isOpen.value = false;
  }

  function toggle() {
    isOpen.value = !isOpen.value;
  }

  return { isOpen, open, close, toggle };
}
