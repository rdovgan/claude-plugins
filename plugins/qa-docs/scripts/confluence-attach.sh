#!/usr/bin/env bash
# Uploads the diagrams of one Confluence page of a domain as attachments of that page, so the page shows
# the PNG instead of a path. The Atlassian MCP server cannot upload attachments, so this goes to the
# Confluence REST API with the user's personal API token (QA_DOCS_CONFLUENCE_EMAIL, QA_DOCS_CONFLUENCE_TOKEN).
# Only pages qa-docs exported for this domain (meta.json) are touched; only attachments are written.
# Usage: confluence-attach.sh <qa-docs/domains/slug> <file.html of confluence/>
# Records each upload in meta.json confluence.attachments["<pageId>/<name>"] = {fileId, collection, sha}
# and skips a diagram whose PNG did not change since. Prints one line per diagram; exit 1 on any failure.
# shellcheck source=../hooks/scripts/lib.sh
. "$(dirname "$0")/../hooks/scripts/lib.sh"
set -u

[ "$#" -eq 2 ] || { echo "usage: confluence-attach.sh <qa-docs/domains/slug> <file.html>" >&2; exit 2; }
command -v jq >/dev/null 2>&1 || { echo "confluence-attach: jq is required" >&2; exit 2; }
command -v curl >/dev/null 2>&1 || { echo "confluence-attach: curl is required; ask the admin" >&2; exit 2; }

dom="$(qd_realpath "$(qd_abspath "$1")")"
base="$(qd_realpath "$(qd_domains)")"
case "$dom" in "$base"/*) ;; *) echo "confluence-attach: '$1' is not a folder under $base" >&2; exit 2 ;; esac
rel="${dom#"$base"/}"; dom="$base/${rel%%/*}"
file="$2"
case "$file" in *[!a-z0-9.-]*|*..*) echo "confluence-attach: bad page file '$file'" >&2; exit 2 ;; esac
meta="$dom/meta.json"; idx="$dom/confluence/pages.json"; page="$dom/confluence/$file"
[ -f "$page" ] && [ -f "$idx" ] && [ -f "$meta" ] || { echo "confluence-attach: $file, pages.json or meta.json is missing in $dom" >&2; exit 2; }

missing=""
for v in QA_DOCS_CONFLUENCE_EMAIL QA_DOCS_CONFLUENCE_TOKEN; do
  [ -n "${!v:-}" ] || missing="$missing $v"
done
if [ -n "$missing" ]; then
  echo "confluence-attach: missing:$missing. Create a token at https://id.atlassian.com/manage-profile/security/api-tokens and export both variables in your shell profile (server/README.md). Until then the pages show the picture paths instead of the pictures." >&2
  exit 3
fi
site="$(qd_conf QA_DOCS_CONFLUENCE_CLOUD)"
[ -n "$site" ] || { echo "confluence-attach: QA_DOCS_CONFLUENCE_CLOUD is not set in .qa-docs/config.env" >&2; exit 2; }
case "$site" in http*) ;; *) site="https://$site" ;; esac
site="${site%/}"

# The page id: the root page is confluence.pageId, the others confluence.pages["<doc path>"].pageId.
read -r parent doc < <(jq -r --arg f "$file" '.pages[] | select(.file == $f) | [(.parent // "-"), (.doc // "-")] | join(" ")' "$idx")
[ -n "${parent:-}" ] || { echo "confluence-attach: $file is not in pages.json" >&2; exit 2; }
if [ "$parent" = "-" ]; then
  pid="$(jq -r '.confluence.pageId // empty' "$meta")"
else
  pid="$(jq -r --arg d "$doc" '.confluence.pages[$d].pageId // empty' "$meta")"
fi
[ -n "$pid" ] || { echo "confluence-attach: $file has no Confluence page yet (create it first, then attach)" >&2; exit 2; }
case "$pid" in *[!0-9]*) echo "confluence-attach: page id '$pid' is not numeric" >&2; exit 2 ;; esac

sha() { if command -v sha256sum >/dev/null 2>&1; then sha256sum "$1" | cut -d' ' -f1; else shasum -a 256 "$1" | cut -d' ' -f1; fi; }

# Credentials go through stdin (curl -K -), never on the command line.
upload() {
  printf 'user = "%s:%s"\n' "$QA_DOCS_CONFLUENCE_EMAIL" "$QA_DOCS_CONFLUENCE_TOKEN" \
    | curl -K - -sS --fail --max-time 120 -X PUT -H 'X-Atlassian-Token: nocheck' \
        -F "file=@$1;type=image/png" -F 'minorEdit=true' -F 'comment=qa-docs diagram' \
        "$site/wiki/rest/api/content/$pid/child/attachment"
}

fails=0; done_n=0; kept=0
for name in $(grep -oE 'data-diagram="[a-z0-9-]+"' "$page" | sed -E 's/.*="(.*)"/\1/' | sort -u); do
  png="$dom/doc/diagrams/$name.png"
  [ -f "$png" ] || { echo "missing  $name.png: run render-diagrams.sh"; fails=$((fails + 1)); continue; }
  key="$pid/$name"; s="$(sha "$png")"
  if [ "$(jq -r --arg k "$key" '.confluence.attachments[$k].sha // empty' "$meta")" = "$s" ]; then
    echo "same     $name"; kept=$((kept + 1)); continue
  fi
  if ! resp="$(upload "$png")"; then
    echo "failed   $name (check the token, the email and your permission to edit page $pid)"; fails=$((fails + 1)); continue
  fi
  fid="$(jq -r '(.results[0] // .).extensions.fileId // empty' <<<"$resp" 2>/dev/null)"
  coll="$(jq -r '(.results[0] // .).extensions.collectionName // empty' <<<"$resp" 2>/dev/null)"
  [ -n "$fid" ] || { echo "failed   $name (no file id in the response)"; fails=$((fails + 1)); continue; }
  # Rewritten in place (not moved over), so the shared file keeps its group and mode.
  tmp="$(mktemp "${TMPDIR:-/tmp}/qa-docs-meta.XXXXXX")"
  if jq --arg k "$key" --arg f "$fid" --arg c "${coll:-contentId-$pid}" --arg s "$s" \
      '.confluence.attachments = ((.confluence.attachments // {}) + {($k): {fileId: $f, collection: $c, sha: $s}})' "$meta" > "$tmp"; then
    cat "$tmp" > "$meta"; rm -f "$tmp"
  else
    rm -f "$tmp"; echo "failed   $name (cannot update meta.json)"; fails=$((fails + 1)); continue
  fi
  echo "uploaded $name"; done_n=$((done_n + 1))
done
echo "attachments: page $pid, $done_n uploaded, $kept unchanged, $fails failed"
[ "$fails" -eq 0 ]
