#!/usr/bin/env bash
# PostToolUse hook: lint/format-check only the file Claude just edited.
#
# Only real findings block (exit 2, output goes back to Claude). A missing or
# broken toolchain, or a timeout, is skipped silently, so a bad environment
# can never wedge a session.
input=$(cat)
file=$(jq -r '.tool_input.file_path // empty' <<< "$input")
[ -n "$file" ] && [ -f "$file" ] || exit 0
root=${CLAUDE_PROJECT_DIR:-$(pwd)}

# Run a command; block only if it exits with a real failure.
check() {
  local out status
  out=$(timeout "${CHECK_TIMEOUT:-30}" "$@" 2>&1)
  status=$?
  [ "$status" -eq 0 ] || [ "$status" -eq 124 ] && return 0
  printf '%s\n' "$out" >&2
  exit 2
}

case "$file" in
  *.rb | *.rake)
    cd "$root" || exit 0
    bundle check > /dev/null 2>&1 || exit 0
    check bundle exec rubocop --force-exclusion "$file"
    ;;
  */frontend/src/*.ts | */frontend/src/*.vue)
    # Tell the Stop hook (stop-typecheck.sh) this turn touched the frontend.
    session=$(jq -r '.session_id // empty' <<< "$input")
    if [ -n "$session" ]; then
      mkdir -p "${TMPDIR:-/tmp}/vglist-claude-hooks" 2> /dev/null &&
        touch "${TMPDIR:-/tmp}/vglist-claude-hooks/frontend-edited-$session" 2> /dev/null
    fi
    bin="$root/frontend/node_modules/.bin"
    [ -x "$bin/oxlint" ] && [ -x "$bin/oxfmt" ] || exit 0
    cd "$root/frontend" || exit 0
    check "$bin/oxlint" "$file"
    check "$bin/oxfmt" --check "$file"
    ;;
esac
exit 0
