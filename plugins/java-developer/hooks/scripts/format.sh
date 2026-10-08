#!/usr/bin/env bash
# PostToolUse Edit|Write: format *.java and run checkstyle (if configured in pom.xml).
# shellcheck source=lib.sh
. "$(dirname "$0")/lib.sh"
jt_require_jq
file="$(jq -r '.tool_input.file_path // empty' <<<"$(cat)")"
case "$file" in *.java) ;; *) exit 0 ;; esac
[ -f "$file" ] || exit 0

mod="$(jt_module_dir "$file")" || exit 0
root="$(jt_repo_root "$file")" || exit 0
export JT_REPO_ROOT="$root"
command -v mvn >/dev/null 2>&1 || [ -x "$root/mvnw" ] || exit 0
pom="$mod/pom.xml"
# Configuration may live in the root pom (pluginManagement/build).
poms="$pom $root/pom.xml"
has() { grep -qs "$1" $poms; }

if has spotless-maven-plugin; then
  jt_mvn -q -f "$pom" spotless:apply "-DspotlessFiles=.*$(basename "$file")" >/dev/null 2>&1
elif has fmt-maven-plugin; then
  jt_mvn -q -f "$pom" com.spotify.fmt:fmt-maven-plugin:format >/dev/null 2>&1
elif has formatter-maven-plugin; then
  jt_mvn -q -f "$pom" formatter:format >/dev/null 2>&1
fi

if has maven-checkstyle-plugin; then
  if ! out="$(jt_mvn -q -f "$pom" checkstyle:check 2>&1)"; then
    echo "Checkstyle violations after changing $file:" >&2
    printf '%s\n' "$out" | grep -E 'WARN|ERROR' | head -n 30 >&2
    exit 2
  fi
fi
exit 0
