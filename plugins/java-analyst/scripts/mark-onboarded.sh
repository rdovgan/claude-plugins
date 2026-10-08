#!/usr/bin/env bash
# Marks onboarding as done so the SessionStart hint stops appearing.
# --reset: forget it, so the hint shows again (for demos).
# CLAUDE_PLUGIN_DATA is set for hooks but not always for the Bash tool, so fall back to the real plugin data dir.
d="${CLAUDE_PLUGIN_DATA:-}"
if [ -z "$d" ]; then
  for c in "$HOME"/.claude/plugins/data/java-analyst-*; do [ -d "$c" ] && d="$c" && break; done
fi
[ -n "$d" ] || d="${TMPDIR:-/tmp}/java-analyst"
mkdir -p "$d" || exit 0
if [ "${1:-}" = "--reset" ]; then
  rm -f "$d/onboarded" "$d/hint.count" && echo "onboarding state reset ($d)"
else
  : > "$d/onboarded" && echo "onboarding marked as done ($d)"
fi
