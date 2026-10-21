#!/usr/bin/env bash
# Stop: every domain written in this session must be consistent: meta.json, no {{placeholders}},
# a flow diagram, a sources section, working code references, and a history entry for this session.
# Blocks once; with stop_hook_active it only warns, so there is no loop.
# shellcheck source=lib.sh
. "$(dirname "$0")/lib.sh"
qd_require_jq

input="$(cat)"
sid="$(jq -r '.session_id // "unknown"' <<<"$input")"
active="$(jq -r '.stop_hook_active // false' <<<"$input")"
data="$(qd_data_dir)"
marker="$data/start.$sid"
dom="$(qd_domains)"
[ -d "$dom" ] && [ -f "$marker" ] || exit 0

problems=""
add() { problems="$problems
- $1"; }

touched="$(find "$dom" -type f -newer "$marker" -not -path '*/work/*' 2>/dev/null | sed "s#^$dom/##; s#/.*##" | sort -u)"
today="$(date +%Y-%m-%d)"
for d in $touched; do
  dir="$dom/$d"
  [ -f "$dir/meta.json" ] || { add "$d/meta.json is missing"; continue; }
  jq -e . "$dir/meta.json" >/dev/null 2>&1 || { add "$d/meta.json is not valid JSON"; continue; }
  jq -e '.modules | type == "object" and length > 0' "$dir/meta.json" >/dev/null 2>&1 || \
    add "$d/meta.json has no \"modules\" with the commit of every repository the document relies on"
  for f in "$dir"/*.md; do
    [ -f "$f" ] && grep -q '{{' "$f" && add "$d/$(basename "$f") still has {{placeholders}}"
  done
  if [ -f "$dir/domain.md" ]; then
    grep -q '^```mermaid' "$dir/domain.md" || add "$d/domain.md has no mermaid flow diagram"
    grep -qE '^## .*(Sources|Джерела)' "$dir/domain.md" || add "$d/domain.md has no Sources section (commits, tickets, pages)"
    refs="$("$(dirname "$0")/../../scripts/check-refs.sh" "$dir" 2>/dev/null | grep -v '^refs:' | head -n 15)"
    [ -n "$refs" ] && add "broken code references:
$(printf '%s\n' "$refs" | sed 's/^/    /')"
  fi
  grep -q "$today" "$dir/history.md" 2>/dev/null || \
    add "$d/history.md has no entry for today: append what this session did, who ($(qd_user)), and the commits it used"
done

# Sources moved under the session (cron ran mid-session): references may point at two different versions.
if [ -s "$data/shas.$sid" ] && [ -n "$touched" ]; then
  moved="$(qd_current_shas | diff "$data/shas.$sid" - 2>/dev/null | grep '^>' | cut -f1 | sed 's/^> //' | tr '\n' ' ')"
  [ -n "$moved" ] && add "these repositories were updated during the session: $moved- re-check the facts that cite them and record the new commits in meta.json"
fi

[ -n "$problems" ] || exit 0
msg="The documentation is not consistent yet:$problems
Fix what you can with your tools. Do not invent facts to pass this check: if something needs more research, do it, or tell the user what is missing and why."
if [ "$active" = true ]; then
  echo "qa-docs: $msg" >&2
  exit 0
fi
jq -n --arg r "$msg" '{decision: "block", reason: $r}'
exit 0
