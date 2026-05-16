#!/usr/bin/env bash
# Post-edit advisory: when an agent edits a .ts/.tsx file, emit a non-blocking
# reminder to type-check before commit. Intentionally non-blocking — full
# project tsc would slow every edit, and per-file tsc gives false positives.
# When HELIX or BackEndAgent want a real gate, swap this for a cached
# whole-project tsc with a per-SHA cache (bartolli-style).
#
# Triggered by: PostToolUse on Edit / Write.

set -e

input=$(cat)
file=$(printf '%s' "$input" | jq -r '.tool_input.file_path // empty' 2>/dev/null)

case "$file" in
  *.ts|*.tsx)
    echo "[hint] edited $file — run 'npm run build' (or 'tsc --noEmit') before commit." >&2
    ;;
esac

exit 0
