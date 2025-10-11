// Make Single File Components work with TypeScript.
// See https://github.com/microsoft/TypeScript-Vue-Starter/tree/c243b11a6f827e780a5163999bc472c95ff5a0e0#single-file-components
export {};

declare module 'vue' {
  import { CompatVue } from '@vue/runtime-dom';
  const Vue: CompatVue;
  export default Vue;
  export * from '@vue/runtime-dom';
  const { configureCompat } = Vue;
  export { configureCompat };
}

