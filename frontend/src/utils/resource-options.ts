export interface IdName {
  id: string;
  name: string;
}

/**
 * Merges a record's own selections into a dropdown's loaded options.
 *
 * The game form loads each resource list in one page, and the API caps a
 * page at 100 records, so a game's engine, series, etc. can be missing from
 * the loaded options. The dropdowns look up the names of selected ids in
 * their options, so a missing one wouldn't be shown at all. Appending the
 * record's own selections (deduplicated by id) keeps them visible and
 * removable.
 */
export function withSelectedOptions(loaded: readonly IdName[], ...selectedLists: readonly IdName[][]): IdName[] {
  const seen = new Set(loaded.map((option) => option.id));
  const merged = [...loaded];
  for (const option of selectedLists.flat()) {
    if (seen.has(option.id)) continue;
    seen.add(option.id);
    merged.push({ id: option.id, name: option.name });
  }
  return merged;
}
