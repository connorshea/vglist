---
name: codegen-sync
description: Regenerate GraphQL schema and TypeScript types after GraphQL changes. Claude invokes this automatically.
user-invocable: false
---

# Codegen Sync

When any of these files are created or modified during a conversation, run the codegen pipeline.

## Trigger files

- `app/graphql/types/**/*.rb` (GraphQL type definitions)
- `app/graphql/mutations/**/*.rb` (GraphQL mutations)
- `app/graphql/resolvers/**/*.rb` (GraphQL resolvers)
- `frontend/src/graphql/queries/**/*.ts` (Frontend query documents)
- `frontend/src/graphql/mutations/**/*.ts` (Frontend mutation documents)

## Pipeline

Run these steps in order:

### Step 1: Regenerate schema.graphql from Ruby types

```bash
bundle exec rake graphql:schema:idl
```

This reads the Ruby GraphQL type/mutation/resolver definitions and outputs `schema.graphql` at the project root.

### Step 2: Regenerate TypeScript types from schema + operations

```bash
cd frontend && yarn codegen
```

This runs `@graphql-codegen/cli` which reads `schema.graphql` and all `frontend/src/graphql/**/*.ts` operation documents, then writes `frontend/src/types/graphql.ts`.

**IMPORTANT**: Never manually edit `frontend/src/types/graphql.ts` — it is fully auto-generated.

### Step 3: Verify types compile

```bash
cd frontend && yarn typecheck
```

If typecheck fails, the frontend code likely references fields that were renamed or removed in the schema change. Fix the frontend code, not the generated types.

## When to skip

- If only frontend `.vue` component files changed (no GraphQL operation changes), skip this pipeline.
- If the user explicitly says they'll run codegen themselves, skip it.

## Notes

- The codegen config is at `frontend/codegen.ts`.
- Schema lint can be run separately: `cd frontend && yarn lint:schema`.
- After codegen, `yarn fmt` runs automatically (configured in the codegen npm script) to format the generated file.
