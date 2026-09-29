#!/usr/bin/env bash
# Запускає MCP-сервер БД (лише читання). Без змінних середовища не стартує,
# решта плагіна працює. Облікові дані беруться лише зі змінних розробника.
# СУБД поки припущено PostgreSQL; див. docs/decisions.md (D-05).
set -u

missing=""
for v in JAVA_TEAM_DB_URL JAVA_TEAM_DB_USER JAVA_TEAM_DB_PASSWORD; do
  [ -n "${!v:-}" ] || missing="$missing $v"
done
if [ -n "$missing" ]; then
  echo "java-team: сервер БД не запущено, не задано:$missing (див. docs/install.md)" >&2
  exit 1
fi

# JAVA_TEAM_DB_URL: postgresql://host:port/dbname (без облікових даних)
scheme="${JAVA_TEAM_DB_URL%%://*}"
rest="${JAVA_TEAM_DB_URL#*://}"
exec npx -y @modelcontextprotocol/server-postgres \
  "${scheme}://${JAVA_TEAM_DB_USER}:${JAVA_TEAM_DB_PASSWORD}@${rest}"
