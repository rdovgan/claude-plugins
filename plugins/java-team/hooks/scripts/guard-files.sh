#!/usr/bin/env bash
# PreToolUse Read|Edit|Write: другий рівень захисту чутливих файлів.
# shellcheck source=lib.sh
. "$(dirname "$0")/lib.sh"
jt_require_jq

input="$(cat)"
tool="$(jq -r '.tool_name // empty' <<<"$input")"
file="$(jq -r '.tool_input.file_path // .tool_input.path // empty' <<<"$input")"
[ -n "$file" ] || exit 0

if jt_is_sensitive "$file"; then
  echo "java-team: доступ до '$file' заблоковано (секрети, прод-конфіги, персональні дані). Працюй із application-local*/application-test* або попроси розробника надати потрібні значення." >&2
  exit 2
fi

# test-writer змінює лише src/test/**
agent="$(jq -r '.agent_type // empty' <<<"$input")"
if [ "$agent" = "test-writer" ] && [ "$tool" != "Read" ]; then
  case "$file" in
    */src/test/*|src/test/*) ;;
    *)
      echo "java-team: test-writer може змінювати лише src/test/**. Якщо тест виявив баг — повідом про нього, не виправляй продакшн-код." >&2
      exit 2
      ;;
  esac
fi
exit 0
