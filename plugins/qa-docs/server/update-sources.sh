#!/usr/bin/env bash
# Admin script (cron), not for the agent: brings every source repository in the workspace to the tip of
# its main branch and writes .qa-docs/sources.tsv, which the plugin reads to warn about stale sources.
#   update-sources.sh /path/to/projects
# Branch per repository: .qa-docs/branches.conf ("repo branch" lines), otherwise origin/HEAD,
# otherwise main, otherwise master. The working trees are disposable mirrors: local changes and
# untracked files are discarded.
set -u
root="${1:-${QA_DOCS_ROOT:-}}"
[ -n "$root" ] && [ -d "$root" ] || { echo "usage: $0 <workspace dir>" >&2; exit 2; }
root="$(cd -P "$root" && pwd)"
admin="$root/.qa-docs"
mkdir -p "$admin"
log="$admin/update.log"
tsv="$admin/sources.tsv"

# One run at a time.
exec 9>"$admin/update.lock"
if command -v flock >/dev/null 2>&1; then
  flock -n 9 || { echo "$(date '+%F %T') another update is running" >> "$log"; exit 0; }
fi

branch_for() {
  local repo="$1" b
  b="$(awk -v r="$(basename "$repo")" '$1 == r { print $2 }' "$admin/branches.conf" 2>/dev/null | tail -n1)"
  [ -n "$b" ] && { printf '%s' "$b"; return; }
  b="$(git -C "$repo" symbolic-ref --short -q refs/remotes/origin/HEAD 2>/dev/null)"
  [ -n "$b" ] && { printf '%s' "${b#origin/}"; return; }
  for b in main master; do
    git -C "$repo" show-ref -q --verify "refs/remotes/origin/$b" && { printf '%s' "$b"; return; }
  done
}

tmp="$(mktemp "$admin/sources.XXXXXX")"
printf 'repo\tbranch\tcommit\tcommit_date\tupdated_at\tstatus\n' > "$tmp"
echo "$(date '+%F %T') update start" >> "$log"
for d in "$root"/*/; do
  repo="${d%/}"
  [ -e "$repo/.git" ] || continue
  name="$(basename "$repo")"
  status=ok
  if ! git -C "$repo" fetch -q --prune origin >> "$log" 2>&1; then
    status=fetch-failed
  fi
  b="$(branch_for "$repo")"
  if [ -z "$b" ]; then
    status=no-branch
  elif [ "$status" = ok ]; then
    if git -C "$repo" checkout -q -f -B "$b" "origin/$b" >> "$log" 2>&1 && git -C "$repo" clean -q -fd >> "$log" 2>&1; then :
    else status=checkout-failed; fi
  fi
  sha="$(git -C "$repo" rev-parse --short=12 HEAD 2>/dev/null)"
  cdate="$(git -C "$repo" log -1 --format=%cs 2>/dev/null)"
  # updated_at = time of the last successful update; a failed run keeps the previous one.
  if [ "$status" = ok ]; then at="$(date +%s)"
  else at="$(awk -F'\t' -v r="$name" '$1 == r { print $5 }' "$tsv" 2>/dev/null)"; at="${at:-0}"; fi
  printf '%s\t%s\t%s\t%s\t%s\t%s\n' "$name" "${b:-?}" "${sha:-?}" "${cdate:-?}" "$at" "$status" >> "$tmp"
  echo "$(date '+%F %T') $name $b $sha $status" >> "$log"
done
chmod 644 "$tmp"
mv "$tmp" "$tsv"
echo "$(date '+%F %T') update done" >> "$log"
