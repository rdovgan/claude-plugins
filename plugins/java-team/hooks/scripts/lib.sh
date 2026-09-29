#!/usr/bin/env bash
# Спільні функції хуків java-team. Підключається через `source`.
# Залежності: bash, jq, git, mvn. Вміст файлів із секретами тут не читається.

# Без jq хук лише попереджає і завершується з кодом 0.
jt_require_jq() {
  command -v jq >/dev/null 2>&1 || {
    echo "java-team: jq не знайдено, хук пропущено" >&2
    exit 0
  }
}

jt_project_dir() { printf '%s' "${CLAUDE_PROJECT_DIR:-$PWD}"; }

jt_data_dir() {
  local d="${CLAUDE_PLUGIN_DATA:-${TMPDIR:-/tmp}/java-team}"
  mkdir -p "$d" 2>/dev/null
  printf '%s' "$d"
}

# Ключ Jira з рядка (перший збіг), формат ABC-123.
jt_jira_key() { printf '%s' "$1" | grep -oE '[A-Z][A-Z0-9]+-[0-9]+' | head -n1; }

jt_branch() { git -C "$(jt_project_dir)" symbolic-ref --short -q HEAD 2>/dev/null; }

# Чутливий шлях за іменем (вміст не читається). Код 0 = чутливий.
jt_is_sensitive() {
  local p="${1%/}" b
  b="${p##*/}"
  case "$b" in
    application-test*|application-local*) return 1 ;;
    .env|.env.*|application-prod*|application-stage*|credentials*) return 0 ;;
    *.pem|*.key|*.jks|*.p12|*.keystore) return 0 ;;
  esac
  case "$p" in
    */secrets/*|secrets/*|*/secrets|secrets) return 0 ;;
    */.ssh/*|*/.aws/*|*/.m2/settings.xml|~/.ssh/*|~/.aws/*|~/.m2/settings.xml) return 0 ;;
  esac
  return 1
}

# Найближча тека з pom.xml, піднімаючись від файлу не вище кореня проєкту.
jt_module_dir() {
  local root d
  root="$(jt_project_dir)"
  d="$(dirname "$1")"
  while [ "$d" != "/" ] && [ "${#d}" -ge "${#root}" ]; do
    [ -f "$d/pom.xml" ] && { printf '%s' "$d"; return 0; }
    d="$(dirname "$d")"
  done
  return 1
}

# ./mvnw, якщо є в проєкті, інакше mvn.
jt_mvn() {
  local root
  root="$(jt_project_dir)"
  if [ -x "$root/mvnw" ]; then "$root/mvnw" "$@"; else mvn "$@"; fi
}
