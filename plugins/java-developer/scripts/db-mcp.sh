#!/usr/bin/env bash
# Starts the DB MCP server (MySQL, read-only). Does not start without the environment variables;
# the rest of the plugin keeps working. Credentials come only from the developer's variables.
# Verify the server and its variables against its docs; see docs/decisions.md (D-05).
set -u

missing=""
for v in JAVA_TEAM_DB_URL JAVA_TEAM_DB_USER JAVA_TEAM_DB_PASSWORD; do
  [ -n "${!v:-}" ] || missing="$missing $v"
done
if [ -n "$missing" ]; then
  echo "java-developer: DB server not started, missing:$missing (see docs/install.md)" >&2
  exit 1
fi

# JAVA_TEAM_DB_URL: mysql://host[:port]/dbname (without credentials)
rest="${JAVA_TEAM_DB_URL#*://}"
hostport="${rest%%/*}"
db="${rest#*/}"; db="${db%%\?*}"
host="${hostport%%:*}"
port="3306"; [[ "$hostport" == *:* ]] && port="${hostport##*:}"

export MYSQL_HOST="$host" MYSQL_PORT="$port" MYSQL_DB="$db"
export MYSQL_USER="$JAVA_TEAM_DB_USER" MYSQL_PASS="$JAVA_TEAM_DB_PASSWORD"
export ALLOW_INSERT_OPERATION=false ALLOW_UPDATE_OPERATION=false ALLOW_DELETE_OPERATION=false
exec npx -y @benborla29/mcp-server-mysql@2.0.9
