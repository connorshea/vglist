import type { CodegenConfig } from '@graphql-codegen/cli'

const config: CodegenConfig = {
  schema: '../schema.graphql',
  documents: [
    'src/graphql/**/*.ts',
    // Exclude files with mutations not yet in the GraphQL schema
    '!src/graphql/mutations/auth.ts',
    '!src/graphql/mutations/users-settings.ts',
  ],
  generates: {
    'src/types/graphql.ts': {
      plugins: ['typescript', 'typescript-operations'],
      config: {
        // Use 'string' for all ID fields since GraphQL IDs come as strings
        scalars: {
          ID: 'string',
          ISO8601Date: 'string',
          ISO8601DateTime: 'string',
        },
        // Avoid __typename in generated types
        skipTypename: true,
        // Use 'interface' for generated types
        declarationKind: 'interface',
        // Generate enums as union types
        enumsAsTypes: true,
        // Make nullable fields use 'T | null'
        maybeValue: 'T | null',
      },
    },
  },
}

export default config
