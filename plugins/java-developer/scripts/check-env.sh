#!/usr/bin/env bash
# Read-only environment check for the onboarding tour. Prints statuses only, never values.
chk() { if command -v "$1" >/dev/null 2>&1; then echo "ok    $1"; else echo "MISS  $1 - $2"; fi; }
chk git "required"
chk jq "hooks only warn without it: brew install jq"
chk mvn "or use the project's ./mvnw"
if command -v java >/dev/null 2>&1; then echo "ok    java ($(java -version 2>&1 | head -n1))"; else echo "MISS  java"; fi
[ -x ./mvnw ] && echo "ok    ./mvnw in this project" || echo "info  no ./mvnw in this directory"
for v in JAVA_TEAM_VAULT JAVA_TEAM_DB_URL JAVA_TEAM_DB_USER JAVA_TEAM_DB_PASSWORD; do
  if [ -n "${!v:-}" ]; then echo "ok    $v is set"; else echo "MISS  $v is not set"; fi
done
[ -f CLAUDE.md ] && echo "ok    CLAUDE.md in this directory" || echo "info  no CLAUDE.md here (project-init not run)"
b="$(git symbolic-ref --short -q HEAD 2>/dev/null)"
[ -n "$b" ] && echo "info  git branch: $b"
exit 0
