// graphql-codegen plugin that writes the GraphQL operation allowlist.
//
// The API only executes operations listed in `config/graphql/operations.json`
// (see `GraphqlOperationAllowlist` on the Rails side), so that the GraphQL
// endpoint can't be used to send arbitrary queries. This plugin collects every
// operation the SPA defines under `src/graphql/`, inlines the fragments each one
// uses, and emits a JSON object mapping operation name => document.
//
// The Rails side compares documents structurally (it parses and re-prints
// them), so whitespace and fragment order don't need to match what
// graphql-request sends.
import { Kind, print, visit } from "graphql";

export const plugin = (_schema, documents) => {
  const fragments = new Map();
  const operations = new Map();

  for (const file of documents) {
    if (!file.document) continue;

    for (const definition of file.document.definitions) {
      if (definition.kind === Kind.FRAGMENT_DEFINITION) {
        fragments.set(definition.name.value, definition);
      } else if (definition.kind === Kind.OPERATION_DEFINITION) {
        if (!definition.name) {
          throw new Error(`Anonymous operation in ${file.location}; every operation needs a name.`);
        }
        const name = definition.name.value;
        if (operations.has(name)) {
          throw new Error(`Duplicate operation name "${name}" in ${file.location}.`);
        }
        operations.set(name, definition);
      }
    }
  }

  // Names of every fragment a node spreads, directly or through other fragments.
  const fragmentsUsedBy = (node, seen = new Set()) => {
    visit(node, {
      FragmentSpread(spread) {
        const name = spread.name.value;
        if (seen.has(name)) return;

        const fragment = fragments.get(name);
        if (!fragment) throw new Error(`Unknown fragment "${name}".`);

        seen.add(name);
        fragmentsUsedBy(fragment, seen);
      }
    });
    return seen;
  };

  const byName = (a, b) => (a < b ? -1 : a > b ? 1 : 0);
  const manifest = {};
  for (const name of [...operations.keys()].sort(byName)) {
    const operation = operations.get(name);
    const used = [...fragmentsUsedBy(operation)].sort(byName).map((fragment) => fragments.get(fragment));
    manifest[name] = print({ kind: Kind.DOCUMENT, definitions: [operation, ...used] });
  }

  return `${JSON.stringify(manifest, null, 2)}\n`;
};
