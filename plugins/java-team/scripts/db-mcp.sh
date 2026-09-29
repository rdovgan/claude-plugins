#!/usr/bin/env bash
# Запускає MCP-сервер БД (MySQL, лише читання). Без змінних середовища не стартує,
# решта плагіна працює. Облікові дані беруться лише зі змінних розробника.
# Сервер і його змінні звірити з документацією; див. docs/decisions.md (D-05).
set -u

missing=""
for v in JAVA_TEAM_DB_URL JAVA_TEAM_DB_USER JAVA_TEAM_DB_PASSWORD; do
  [ -n "${!v:-}" ] || missing="$missing $v"
done
if [ -n "$missing" ]; then
  echo "java-team: сервер БД не запущено, не задано:$missing (див. docs/install.md)" >&2
  exit 1
fi

# JAVA_TEAM_DB_URL: mysql://host[:port]/dbname (без облікових даних)
rest="${JAVA_TEAM_DB_URL#*://}"
hostport="${rest%%/*}"
db="${rest#*/}"; db="${db%%\?*}"
host="${hostport%%:*}"
port="3306"; [[ "$hostport" == *:* ]] && port="${hostport##*:}"

export MYSQL_HOST="$host" MYSQL_PORT="$port" MYSQL_DB="$db"
export MYSQL_USER="$JAVA_TEAM_DB_USER" MYSQL_PASS="$JAVA_TEAM_DB_PASSWORD"
export ALLOW_INSERT_OPERATION=false ALLOW_UPDATE_OPERATION=false ALLOW_DELETE_OPERATION=false
exec npx -y @benborla29/mcp-server-mysql
