#!/usr/bin/env bash
# SessionStart: stdout goes into the agent's context.
# shellcheck source=lib.sh
. "$(dirname "$0")/lib.sh"
qd_require_jq

sid="$(jq -r '.session_id // "unknown"' <<<"$(cat)")"
root="$(qd_root)"
out="$(qd_out)"
admin="$(qd_admin_dir)"
data="$(qd_data_dir)"
: > "$data/start.$sid"                       # session start marker for verify-docs.sh
qd_current_shas > "$data/shas.$sid"          # source commits at start; verify-docs.sh compares

lang="$(qd_conf QA_DOCS_LANGUAGE)"
echo "qa-docs: DOCUMENTATION mode for user $(qd_user). Workspace $root: every git folder in it is a read-only source repository (master/main, updated by cron). Never change sources; write documents only in $out/. Start with /qa-docs:document <domain, Jira key or description>; cheat sheet: /qa-docs:help."
echo "qa-docs: the code is the source of truth. Jira and Confluence say what was intended; when they disagree with the code, the document says what the code does and lists the disagreement."
[ -n "$lang" ] && echo "qa-docs: write documents in $lang (team setting)."
echo "qa-docs: research budget QA_DOCS_MAX_SUBFLOWS=$(qd_conf QA_DOCS_MAX_SUBFLOWS 6) sub-flows per run; agents search inside the repositories in scope, never the whole workspace. A plain question goes to /qa-docs:ask, not a full document."

# Sources: freshness and failures reported by server/update-sources.sh.
tsv="$admin/sources.tsv"
if [ -f "$tsv" ]; then
  stale_h="$(qd_conf QA_DOCS_STALE_HOURS 48)"
  now="$(date +%s)"
  bad="$(awk -F'\t' -v now="$now" -v lim="$((stale_h * 3600))" '
    NR > 1 && ($6 != "ok" || now - $5 > lim) { printf "%s(%s, updated %dh ago) ", $1, $6, (now - $5) / 3600 }' "$tsv")"
  if [ -n "$bad" ]; then
    echo "qa-docs: WARNING: some sources are not fresh (limit ${stale_h}h): $bad- tell the user in your first reply; documents built on them may be outdated. The admin's update log is $admin/update.log."
  else
    echo "qa-docs: sources are fresh (updated by cron, see $tsv)."
  fi
else
  echo "qa-docs: WARNING: $tsv is missing, so nobody knows how fresh the sources are (server/update-sources.sh has not run). Tell the user once."
fi

# Maps.
for m in modules.md domains.md; do
  if [ -f "$out/$m" ]; then echo "qa-docs: map $out/$m - read it before researching."
  else echo "qa-docs: $out/$m does not exist yet; /qa-docs:map builds it."; fi
done
main="$(qd_conf QA_DOCS_MAIN_PROJECT)"
[ -n "$main" ] && [ -d "$root/$main" ] && echo "qa-docs: $main is the main project: most business logic lives there."

# Domains: status, last editor, whether the code moved since they were documented.
cur="$data/shas.$sid"
lines=""
for f in "$(qd_domains)"/*/meta.json; do
  [ -f "$f" ] || continue
  slug="$(basename "$(dirname "$f")")"
  changed="$(jq -r '.modules // {} | to_entries[] | "\(.key)\t\(.value)"' "$f" 2>/dev/null | while IFS=$'\t' read -r r s; do
      c="$(awk -F'\t' -v r="$r" '$1 == r { print $2 }' "$cur")"
      [ -n "$c" ] && [ "${c:0:7}" != "${s:0:7}" ] && printf '%s ' "$r"
    done)"
  info="$(jq -r '"\(.status // "draft"), by \(.updatedBy // "?") \(.updatedAt // "")"' "$f" 2>/dev/null)"
  lines="$lines  $slug: $info${changed:+; code changed since: $changed- /qa-docs:refresh $slug}
"
done
if [ -n "$lines" ]; then
  echo "qa-docs: documented domains (continue an existing one instead of starting a duplicate):"
  printf '%s' "$lines"
fi

# Locks held by other sessions.
for l in "$(qd_locks_dir)"/*.lock; do
  [ -f "$l" ] || continue
  read -r osid ouser oat < "$l"
  [ "$osid" = "$sid" ] && continue
  age=$(( ($(date +%s) - ${oat:-0}) / 60 ))
  [ "$age" -lt "$(qd_conf QA_DOCS_LOCK_MINUTES 120)" ] && echo "qa-docs: '$(basename "$l" .lock)' is being edited by $ouser (last write ${age} min ago); it is read-only for this session until they finish."
done

if [ -n "$(qd_conf QA_DOCS_CONFLUENCE_PARENT)" ]; then
  echo "qa-docs: export target: cloud $(qd_conf QA_DOCS_CONFLUENCE_CLOUD), space $(qd_conf QA_DOCS_CONFLUENCE_SPACE), parent page $(qd_conf QA_DOCS_CONFLUENCE_PARENT)."
else
  echo "qa-docs: Confluence export is not configured (.qa-docs/config.env); documents stay local until the admin sets it."
fi

if [ ! -f "$data/onboarded" ]; then
  n="$(cat "$data/hint.count" 2>/dev/null || echo 0)"
  if [ "$n" -lt 3 ] 2>/dev/null; then
    echo "$((n + 1))" > "$data/hint.count"
    echo "qa-docs: this user has not done onboarding yet. Mention once, in one line, at the start of your first reply: /qa-docs:onboarding is a 3-minute tour, /qa-docs:help is the cheat sheet."
  fi
fi
exit 0
