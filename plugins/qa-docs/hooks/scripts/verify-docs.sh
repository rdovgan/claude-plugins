#!/usr/bin/env bash
# Stop: every domain written in this session must be consistent: meta.json, no {{placeholders}},
# the required pages with their diagrams rendered, working links and code references, and a history
# entry for this session.
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
  while IFS= read -r f; do
    grep -q '{{' "$f" && add "$d/${f#"$dir"/} still has {{placeholders}}"
  done < <(find "$dir" -name '*.md' -not -path '*/work/*' -not -path '*/export/*' -not -path '*/source/*' 2>/dev/null)
  doc="$dir/doc"
  if [ -d "$doc" ]; then
    if [ "$(jq -r '.layout // "domain"' "$dir/meta.json")" = mirror ]; then
      [ -f "$doc/page.md" ] || add "$d/doc/page.md is missing: the updated page in the old page's structure"
      [ -f "$doc/changes.md" ] || add "$d/doc/changes.md is missing: what changed against the old page"
    else
      if [ -f "$doc/README.md" ]; then
        grep -q '^```mermaid' "$doc/README.md" || add "$d/doc/README.md has no overview diagram"
        grep -qE '^## .*(Sources|Джерела)' "$doc/README.md" || add "$d/doc/README.md has no Sources section (commits, tickets, pages)"
      else
        add "$d/doc/README.md is missing: the overview page with links to the other pages"
      fi
      ls "$doc"/flows/*.md >/dev/null 2>&1 || add "$d/doc/flows/ has no process page"
      for f in "$doc"/flows/*.md; do
        [ -f "$f" ] && ! grep -q '^```mermaid' "$f" && add "$d/doc/flows/$(basename "$f") has no diagram"
      done
    fi
    # Relative links between pages must point at existing files.
    while IFS= read -r f; do
      while IFS= read -r l; do
        t="${l%%#*}"
        [ -e "$(dirname "$f")/$t" ] || add "$d/${f#"$dir"/}: link to '$t', which does not exist"
      done < <(grep -oE '\]\([^)#[:space:]]+\.md(#[^)]*)?\)' "$f" 2>/dev/null | sed -E 's/^\]\(//; s/\)$//' | grep -vE '^[a-z]+://' | sort -u)
    done < <(find "$doc" -name '*.md' 2>/dev/null)
    pics="$("$(dirname "$0")/../../scripts/render-diagrams.sh" "$dir" --check 2>/dev/null | grep -v '^diagrams:' | head -n 10)"
    [ -n "$pics" ] && add "diagrams not rendered or outdated (run scripts/render-diagrams.sh):
$(printf '%s\n' "$pics" | sed 's/^/    /')"
  elif [ -f "$dir/domain.md" ] && ! grep -q '^```mermaid' "$dir/domain.md" && [ "$(wc -l < "$dir/domain.md")" -gt 3 ]; then
    add "$d/domain.md has no mermaid flow diagram"
  fi
  if [ -d "$doc" ] || [ -f "$dir/domain.md" ]; then
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
