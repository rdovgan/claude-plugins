#!/usr/bin/env bash
# UserPromptSubmit: for a report, the formats selected right now (the formats row may have changed them).
# shellcheck source=lib.sh
. "$(dirname "$0")/lib.sh"
qd_require_jq
prompt="$(jq -r '.prompt // empty' <<<"$(cat)")"
case "$prompt" in
  /qa-docs:report*)
    fmts="$(qd_formats | tr '\n' ' ')"; fmts="${fmts% }"
    echo "qa-docs: formats selected now: ${fmts:-none}. Flags in the command replace them for this run." ;;
esac
exit 0
