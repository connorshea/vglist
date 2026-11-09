import type { CodegenConfig } from "@graphql-codegen/cli";

const config: CodegenConfig = {
  schema: "../schema.graphql",
  // Tests in src/graphql use made-up operations that aren't in the schema.
  documents: ["src/graphql/**/*.ts", "!src/graphql/**/*.test.ts"],
  generates: {
    "src/types/graphql.ts": {
      plugins: ["typescript-operations"],
      config: {
        // Use 'string' for all ID fields since GraphQL IDs come as strings
        scalars: {
          ID: "string",
          ISO8601Date: "string",
          ISO8601DateTime: "string",
          // Only used for WebAuthn options and responses, which are narrowed to
          // @simplewebauthn/browser's types where they're used.
          JSON: "unknown"
        },
        // Avoid __typename in generated types
        skipTypename: true,
        // Use 'interface' for generated types
        declarationKind: "interface",
        // Generate enums as union types
        enumsAsTypes: true,
        // Make nullable fields use 'T | null'
        maybeValue: "T | null"
      }
    },
    // The operation allowlist the API enforces. See codegen/operation-manifest.mjs.
    "../config/graphql/operations.json": {
      plugins: ["./codegen/operation-manifest.mjs"]
    }
  }
};

export default config;
