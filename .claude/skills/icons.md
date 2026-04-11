# Icons Skill

When adding icons to the vglist frontend, follow these rules:

## Rules

1. **Always use Lucide icons** from `lucide-vue-next`. Never create custom SVG icon components or use inline `<svg>` elements for icons.
2. **Import icons by name** directly from `lucide-vue-next`:
   ```vue
   import { Search, ChevronRight, Trash2 } from "lucide-vue-next";
   ```
3. **Use icons in templates** as Vue components:
   ```vue
   <Search :size="20" />
   ```
4. **Browse available icons** at https://lucide.dev/icons/ — search by concept (e.g. "delete", "settings", "user") to find the right icon name.
5. **Allowed SVG exceptions**: The vglist logo files (`vglist-logo.svg`, `vglist-favicon.svg`, `safari-pinned-tab.svg`) are brand assets and should remain as SVGs. Custom data visualizations (like the rating circle in `GameDetailsSection.vue`) that use dynamic SVG with computed attributes are also fine.
6. **Do not** use Font Awesome, Material Icons, Heroicons, or any other icon library.
7. **Size and styling**: Pass `size` as a prop for pixel dimensions. Use CSS classes or Bulma utility classes for color/spacing.
