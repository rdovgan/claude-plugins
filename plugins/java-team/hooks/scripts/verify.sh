#!/usr/bin/env bash
# Stop: тести змінених модулів + одноразове нагадування про session-summary.
# shellcheck source=lib.sh
. "$(dirname "$0")/lib.sh"
jt_require_jq

[ "${JAVA_TEAM_SKIP_VERIFY:-}" = "1" ] && exit 0
command -v git >/dev/null 2>&1 || exit 0

input="$(cat)"
sid="$(jq -r '.session_id // "unknown"' <<<"$input")"
active="$(jq -r '.stop_hook_active // false' <<<"$input")"
root="$(jt_project_dir)"
data="$(jt_data_dir)"
cd "$root" || exit 0

# Змінені .java: робоче дерево відносно бази + нові файли, лише новіші за початок сесії.
base=""
for b in origin/main origin/master main master; do
  git rev-parse --verify -q "$b" >/dev/null 2>&1 && { base="$(git merge-base HEAD "$b" 2>/dev/null)"; break; }
done
{
  git diff --relative --name-only "${base:-HEAD}" 2>/dev/null
  git ls-files --others --exclude-standard 2>/dev/null
} | sort -u | grep -E '\.java$' > "$data/changed.$sid" || true

marker="$data/start.$sid"
files=()
while IFS= read -r f; do
  [ -f "$f" ] || continue
  if [ -f "$marker" ] && [ ! "$f" -nt "$marker" ]; then continue; fi
  files+=("$f")
done < "$data/changed.$sid"
rm -f "$data/changed.$sid"
[ "${#files[@]}" -gt 0 ] || exit 0

# Модулі змінених файлів.
mods=()
for f in "${files[@]}"; do
  m="$(jt_module_dir "$root/$f")" || continue
  rel="${m#"$root"}"; rel="${rel#/}"; [ -n "$rel" ] || rel="."
  case " ${mods[*]:-} " in *" $rel "*) ;; *) mods+=("$rel") ;; esac
done
[ "${#mods[@]}" -gt 0 ] || exit 0

args=(-q -B -Dsurefire.failIfNoSpecifiedTests=false)
if [[ " ${mods[*]} " != *" . "* ]]; then
  args+=(-pl "$(IFS=,; echo "${mods[*]}")" -am)
fi

if ! out="$(jt_mvn "${args[@]}" test 2>&1)"; then
  if [ "$active" = "true" ]; then
    # Уже блокували в цьому циклі: не зациклюємось, лише попереджаємо.
    echo "java-team: тести все ще падають, повторне блокування пропущено (stop_hook_active)." >&2
    exit 0
  fi
  tail_out="$(printf '%s\n' "$out" | tail -n 50)"
  jq -n --arg r "Тести змінених модулів (${mods[*]}) падають. Виправ і заверши знову. Останні 50 рядків виводу mvn:
$tail_out" '{decision: "block", reason: $r}'
  exit 0
fi

# Тести пройшли: один раз на сесію нагадуємо про session-summary.
flag="$data/summary-reminded.$sid"
if [ ! -f "$flag" ]; then
  : > "$flag"
  jq -n '{decision: "block", reason: "Тести пройшли. Запусти скіл session-summary, щоб зберегти підсумок сесії, і після цього завершуй."}'
fi
exit 0
