#!/usr/bin/env bash
# Stop hook: typecheck the frontend, but only if this turn edited frontend
# sources (check-edited-file.sh leaves a per-session marker when it does).
#
# Only real type errors block (exit 2). A missing toolchain or a timeout is
# skipped silently. stop_hook_active means a previous Stop hook already blocked
# this turn, so we let Claude stop rather than loop on a persistent failure.
input=$(cat)
[ "$(jq -r '.stop_hook_active // false' <<< "$input")" = "true" ] && exit 0

session=$(jq -r '.session_id // empty' <<< "$input")
[ -n "$session" ] || exit 0
marker="${TMPDIR:-/tmp}/vglist-claude-hooks/frontend-edited-$session"
[ -f "$marker" ] || exit 0
rm -f "$marker"

root=${CLAUDE_PROJECT_DIR:-$(pwd)}
bin="$root/frontend/node_modules/.bin"
[ -x "$bin/vue-tsc" ] || exit 0
cd "$root/frontend" || exit 0

# vue-tsc can't be scoped to one file, so this checks the whole project.
# Mirrors `pnpm run typecheck`, but calls the local binary so pnpm startup
# (and any package-manager self-install) can't eat the timeout.
out=$(timeout 60 "$bin/vue-tsc" --noEmit 2>&1)
status=$?
[ "$status" -eq 0 ] || [ "$status" -eq 124 ] && exit 0
printf '%s\n' "$out" >&2
exit 2
