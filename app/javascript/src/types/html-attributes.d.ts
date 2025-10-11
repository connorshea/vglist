// Extend Vue's HTML attributes to include modern HTML attributes that TypeScript doesn't recognize yet

// TODO: Get rid of this file when Vue 3 includes popover attributes in its types.
// https://github.com/vuejs/core/pull/13113

declare module '@vue/runtime-dom' {
  interface HTMLAttributes {
    // Popover API attributes
    popover?: boolean | string | 'auto' | 'manual';
    popovertarget?: string;
    popovertargetaction?: 'show' | 'hide' | 'toggle';

    // Data attribute for tooltip placement, there's probably a better way to do this?
    'data-tooltip-placement'?: 'top' | 'bottom' | 'left' | 'right';
  }

  // Merge in support for arbitrary data-* attributes (excluding the specialized one above)
  interface HTMLAttributes extends DataAttributes {}
}

// For Vue 2.7 compatibility
declare module 'vue' {
  interface HTMLAttributes {
    // Popover API attributes
    popover?: boolean | string | 'auto' | 'manual';
    popovertarget?: string;
    popovertargetaction?: 'show' | 'hide' | 'toggle';

    // Data attribute for tooltip placement, there's probably a better way to do this?
    'data-tooltip-placement'?: 'top' | 'bottom' | 'left' | 'right';
  }

  // Merge in support for arbitrary data-* attributes (excluding the specialized one above)
  interface HTMLAttributes extends DataAttributes {}
}

export {};

// Helper mapped type to allow any data-* attribute while preserving specific, stricter keys above
type DataAttributes = {
  // Exclude keys we type explicitly (like 'data-tooltip-placement') to avoid declaration conflicts
  [K in `data-${string}` as K extends 'data-tooltip-placement' ? never : K]?: string | number | boolean;
};
