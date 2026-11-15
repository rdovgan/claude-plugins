#!/usr/bin/env bash
# Builds the visual page of one analysis: <task dir>/visual.json + templates/visual/visual.html -> <task dir>/visual.html.
#   build-visual.sh .claude/analysis/ABC-123
# Writes only that one file, and only inside the project's .claude/analysis/. Needs jq.
set -u
here="$(cd "$(dirname "$0")/.." && pwd)"
tpl="$here/templates/visual/visual.html"
root="${CLAUDE_PROJECT_DIR:-$PWD}"
out_root="$root/.claude/analysis"

die() { echo "build-visual: $1" >&2; exit 1; }
command -v jq >/dev/null 2>&1 || die "jq not found (brew install jq)."
[ $# -eq 1 ] || die "usage: build-visual.sh <task folder>, e.g. .claude/analysis/ABC-123"
case "$1" in /*) dir="$1" ;; *) dir="$root/$1" ;; esac
dir="$(cd "$dir" 2>/dev/null && pwd -P)" || die "folder not found: $1"
real_out="$(cd "$out_root" 2>/dev/null && pwd -P)" || die "no $out_root"
case "$dir" in "$real_out"/*) ;; *) die "the folder must be inside $out_root" ;; esac
[ "$(dirname "$dir")" = "$real_out" ] || die "use the task folder itself: $out_root/<task>"
src="$dir/visual.json"
[ -f "$src" ] || die "no visual.json in $dir; write it first (see the present-visual skill)."
jq -e 'type == "object" and (.meta | type == "object") and (.verdict | type == "object")' "$src" >/dev/null 2>&1 ||
  die "visual.json is not valid JSON with \"meta\" and \"verdict\" objects; fix it and run again."
[ -f "$tpl" ] || die "template missing: $tpl"

tmp="$(mktemp -d "${TMPDIR:-/tmp}/analysis-visual.XXXXXX")" || die "cannot create a temp folder"
trap 'rm -rf "$tmp"' EXIT

# Data for the page script; "</" is escaped so the JSON cannot close its <script> tag.
jq -c --arg folder "${dir#"$root"/}" '.meta.folder = $folder' "$src" | sed 's#</#<\\/#g' > "$tmp/data"
# Flow diagrams as static mermaid blocks (the viewer renders <pre class="mermaid"> itself).
jq -r '(.flows // [])[] | select(.mermaid and (.mermaid | length) > 0) |
  "<figure class=\"flow\"><figcaption><h3>" + ((.title // "") | @html) + "</h3></figcaption>" +
  "<div class=\"canvas\"><pre class=\"mermaid\">\n" + (.mermaid | @html) + "\n</pre></div></figure>"' "$src" > "$tmp/flows"
jq -r '[.meta.key, .meta.title] | map(select(. != null and . != "")) | join(" ") | if . == "" then "Analysis" else . end | @html' "$src" > "$tmp/title"

awk -v data="$tmp/data" -v flows="$tmp/flows" -v title="$tmp/title" '
  function slurp(f,   s, l) { s = ""; while ((getline l < f) > 0) s = s (s == "" ? "" : "\n") l; close(f); return s }
  BEGIN { D = slurp(data); F = slurp(flows); T = slurp(title) }
  index($0, "__TITLE__") { i = index($0, "__TITLE__"); $0 = substr($0, 1, i - 1) T substr($0, i + 9) }
  index($0, "/*__DATA__*/") { i = index($0, "/*__DATA__*/"); $0 = substr($0, 1, i - 1) D substr($0, i + 12) }
  $0 == "<!--__FLOWS__-->" { if (F != "") print F; next }
  { print }
' "$tpl" > "$tmp/page" || die "build failed"
grep -q '__TITLE__\|/\*__DATA__\*/' "$tmp/page" && die "build failed: placeholders left"
cp "$tmp/page" "$dir/visual.html" || die "cannot write $dir/visual.html"
echo "built ${dir#"$root"/}/visual.html ($(wc -c < "$dir/visual.html" | tr -d ' ') bytes)"
