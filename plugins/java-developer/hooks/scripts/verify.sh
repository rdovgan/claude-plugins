#!/usr/bin/env bash
# Stop: tests of changed modules (in every repo of the workspace) + one-time session-summary reminder.
# shellcheck source=lib.sh
. "$(dirname "$0")/lib.sh"
jt_require_jq

[ "${JAVA_TEAM_SKIP_VERIFY:-}" = "1" ] && exit 0
command -v git >/dev/null 2>&1 || exit 0

input="$(cat)"
sid="$(jq -r '.session_id // "unknown"' <<<"$input")"
active="$(jq -r '.stop_hook_active // false' <<<"$input")"
data="$(jt_data_dir)"
marker="$data/start.$sid"

# Changed .java files of one repo (paths relative to it): working tree vs base + new files,
# only those newer than the session start.
changed_java() {
  local repo="$1" base="" b f
  for b in origin/main origin/master main master; do
    git -C "$repo" rev-parse --verify -q "$b" >/dev/null 2>&1 && { base="$(git -C "$repo" merge-base HEAD "$b" 2>/dev/null)"; break; }
  done
  {
    git -C "$repo" diff --relative --name-only "${base:-HEAD}" 2>/dev/null
    git -C "$repo" ls-files --others --exclude-standard 2>/dev/null
  } | sort -u | grep -E '\.java$' | while IFS= read -r f; do
    [ -f "$repo/$f" ] || continue
    if [ -f "$marker" ] && [ ! "$repo/$f" -nt "$marker" ]; then continue; fi
    printf '%s\n' "$f"
  done
}

# Build failures caused by the machine, not by the code (wrong JDK for the repo's Java line, Lombok
# vs JDK, missing JAVA_HOME): reported as a warning, they must not block finishing.
env_re='does not export|IllegalAccessError|Unsupported class file major version|invalid target release|release version [0-9]+ not supported|JAVA_HOME|No compiler is provided|invalid source release'

failed=""
envfailed=""
tested=""
while IFS= read -r repo; do
  [ -n "$repo" ] || continue
  files=()
  while IFS= read -r f; do [ -n "$f" ] && files+=("$f"); done < <(changed_java "$repo")
  [ "${#files[@]}" -gt 0 ] || continue

  # Modules of the changed files.
  mods=()
  for f in "${files[@]}"; do
    m="$(jt_module_dir "$repo/$f")" || continue
    rel="${m#"$repo"}"; rel="${rel#/}"; [ -n "$rel" ] || rel="."
    case " ${mods[*]:-} " in *" $rel "*) ;; *) mods+=("$rel") ;; esac
  done
  [ "${#mods[@]}" -gt 0 ] || continue

  name="$(basename "$repo")"
  tested="$tested $name(${mods[*]})"
  args=(-q -B -Dsurefire.failIfNoSpecifiedTests=false)
  if [[ " ${mods[*]} " != *" . "* ]]; then
    args+=(-pl "$(IFS=,; echo "${mods[*]}")" -am)
  fi

  if ! out="$(cd "$repo" && JT_REPO_ROOT="$repo" jt_mvn "${args[@]}" test 2>&1)"; then
    if grep -qE "$env_re" <<<"$out"; then
      envfailed="$envfailed $name"
      continue
    fi
    failed="$failed
[$name: ${mods[*]}]
$(printf '%s\n' "$out" | tail -n 50)"
  fi
done < <(jt_workspace_repos)

[ -n "$tested" ] || exit 0

if [ -n "$failed" ]; then
  if [ "$active" = "true" ]; then
    # Already blocked in this cycle: avoid looping, only warn.
    echo "java-developer: tests still fail, repeated blocking skipped (stop_hook_active)." >&2
    exit 0
  fi
  jq -n --arg r "Tests of the changed modules fail. Fix them and finish again. Last 50 lines of mvn output per repository:
$failed" '{decision: "block", reason: $r}'
  exit 0
fi

if [ -n "$envfailed" ]; then
  echo "java-developer: tests not run in:$envfailed - the build failed because of the environment (JDK/Lombok/JAVA_HOME for that repo's Java line), not the code. Run them manually with the right JDK." >&2
fi

# Code changed but no spec criterion was ticked this session: remind once.
spec="$(jt_spec_file)" || spec=""
if [ -n "$spec" ] && [ ! -f "$data/spec-reminded.$sid" ]; then
  base_ticks="$(cat "$data/specticks.$sid" 2>/dev/null || echo 0)"
  nums="$(jt_spec_progress "$spec")"; nums="${nums%%|*}"
  set -- $nums
  if [ "$(jt_spec_ticks "$spec")" -le "$base_ticks" ] && [ "${1:-0}" -lt "${2:-0}" ] 2>/dev/null; then
    : > "$data/spec-reminded.$sid"
    jq -n --arg r "Code changed in this session, but no acceptance criterion in ${spec#"$(jt_project_dir)"/} is ticked ($1 of $2 steps done). Tick the criteria you have verified ([x]) and add a one-line Result under the step; if the work is outside the spec, say so and update the spec. Then finish." '{decision: "block", reason: $r}'
    exit 0
  fi
fi

# Remind about session-summary once per session.
flag="$data/summary-reminded.$sid"
if [ ! -f "$flag" ]; then
  : > "$flag"
  if [ -n "$envfailed" ]; then
    msg="Tests could not run in:$envfailed (environment problem, see the warning). Run the session-summary skill to save the session summary, mention this, then finish."
  else
    msg="Tests passed. Run the session-summary skill to save the session summary, then finish."
  fi
  jq -n --arg r "$msg" '{decision: "block", reason: $r}'
fi
exit 0
