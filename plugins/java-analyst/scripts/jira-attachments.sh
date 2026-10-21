#!/usr/bin/env bash
# Downloads the attachments of a Jira ticket to .claude/attachments/<KEY>/ so the agent can Read them.
# The Atlassian MCP server returns attachment metadata only; the content URL needs the user's own
# credentials, so this goes to the Jira REST API with a personal API token (GET only).
# Usage: jira-attachments.sh <KEY> [max MB per file, default 25]
set -u

key="${1:-}"
max_mb="${2:-25}"
if ! [[ "$key" =~ ^[A-Z][A-Z0-9]+-[0-9]+$ ]]; then
  echo "usage: jira-attachments.sh <KEY> [max MB per file]" >&2
  exit 1
fi
command -v jq >/dev/null 2>&1 || { echo "jira-attachments: jq is required (brew install jq)" >&2; exit 1; }

missing=""
for v in JAVA_TEAM_JIRA_URL JAVA_TEAM_JIRA_EMAIL JAVA_TEAM_JIRA_TOKEN; do
  [ -n "${!v:-}" ] || missing="$missing $v"
done
if [ -n "$missing" ]; then
  echo "jira-attachments: missing:$missing. Create a token at https://id.atlassian.com/manage-profile/security/api-tokens and export it (see docs/install.md). Until then ask the user to paste the logs or screenshots." >&2
  exit 1
fi
site="${JAVA_TEAM_JIRA_URL%/}"   # https://<your-site>.atlassian.net

# Credentials go through stdin (curl -K -), never on the command line.
jira_get() {
  printf 'user = "%s:%s"\n' "$JAVA_TEAM_JIRA_EMAIL" "$JAVA_TEAM_JIRA_TOKEN" \
    | curl -K - -sS -L --fail --max-time 120 "$@"
}

meta="$(jira_get "$site/rest/api/3/issue/$key?fields=attachment")" || {
  echo "jira-attachments: cannot read $key from $site (check JAVA_TEAM_JIRA_URL, the email and the token)" >&2
  exit 1
}

count="$(jq '.fields.attachment | length' <<<"$meta")"
if [ "${count:-0}" -eq 0 ]; then
  echo "jira-attachments: $key has no attachments"
  exit 0
fi

root="${CLAUDE_PROJECT_DIR:-$PWD}"
dir="$root/.claude/attachments/$key"
mkdir -p "$dir"
if git -C "$root" rev-parse --is-inside-work-tree >/dev/null 2>&1 \
   && ! git -C "$root" check-ignore -q "$dir/x" 2>/dev/null; then
  printf '\n.claude/attachments/\n' >> "$root/.gitignore"
  echo "jira-attachments: added .claude/attachments/ to .gitignore"
fi

max_bytes=$((max_mb * 1024 * 1024))
jq -r '.fields.attachment[] | [.id, .size, .mimeType, .filename] | @tsv' <<<"$meta" |
while IFS=$'\t' read -r id size mime name; do
  safe="$(printf '%s' "$name" | tr '/\\' '__' | sed 's/^\.*//')"
  out="$dir/$id-${safe:-file}"
  if [ "$size" -gt "$max_bytes" ] 2>/dev/null; then
    echo "skipped  $name ($mime, $((size / 1024 / 1024)) MB > $max_mb MB)"
    continue
  fi
  if [ -s "$out" ]; then
    echo "exists   $out ($mime)"
    continue
  fi
  if jira_get -o "$out" "$site/rest/api/3/attachment/content/$id"; then
    echo "saved    $out ($mime)"
  else
    rm -f "$out"
    echo "failed   $name ($mime)"
  fi
done
exit 0
