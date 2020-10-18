// Make Single File Components work with TypeScript.
// See https://github.com/microsoft/TypeScript-Vue-Starter/tree/c243b11a6f827e780a5163999bc472c95ff5a0e0#single-file-components
// TODO: Remove with Vue 3?
declare module "*.vue" {
  import Vue from "vue";
  export default Vue;
}
