#!/usr/bin/env bash
# Builds the visual overview of one domain: <domain>/visual/visual.json + templates/visual/visual.html
# -> <domain>/visual/visual.html. Same template as the qa-analyst visual page.
#   build-visual.sh qa-docs/domains/<slug>
# Writes only that one file, and only inside qa-docs/domains/. Needs jq.
# shellcheck source=../hooks/scripts/lib.sh
. "$(dirname "$0")/../hooks/scripts/lib.sh"
set -u

die() { echo "build-visual: $1" >&2; exit 1; }
command -v jq >/dev/null 2>&1 || die "jq not found (brew install jq)."
[ $# -eq 1 ] || die "usage: build-visual.sh qa-docs/domains/<slug>"
tpl="$(cd "$(dirname "$0")/.." && pwd)/templates/visual/visual.html"
[ -f "$tpl" ] || die "template missing: $tpl"

dom="$(qd_realpath "$(qd_abspath "$1")")"
base="$(qd_realpath "$(qd_domains)")"
case "$dom" in "$base"/*) ;; *) die "'$1' is not a folder under $base" ;; esac
rel="${dom#"$base"/}"; dom="$base/${rel%%/*}"
dir="$dom/visual"
src="$dir/visual.json"
[ -f "$src" ] || die "no visual/visual.json in $dom; write it first (see the domain-visual skill)."
jq -e 'type == "object" and (.meta | type == "object") and (.verdict | type == "object")' "$src" >/dev/null 2>&1 ||
  die "visual.json is not valid JSON with \"meta\" and \"verdict\" objects; fix it and run again."

tmp="$(mktemp -d "${TMPDIR:-/tmp}/qa-docs-visual.XXXXXX")" || die "cannot create a temp folder"
trap 'rm -rf "$tmp"' EXIT

# Data for the page script; "</" is escaped so the JSON cannot close its <script> tag.
jq -c --arg folder "qa-docs/domains/${dom##*/}" '.meta.folder = $folder' "$src" | sed 's#</#<\\/#g' > "$tmp/data"
jq -r '(.flows // [])[] | select(.mermaid and (.mermaid | length) > 0) |
  "<figure class=\"flow\"><figcaption><h3>" + ((.title // "") | @html) + "</h3></figcaption>" +
  "<div class=\"canvas\"><pre class=\"mermaid\">\n" + (.mermaid | @html) + "\n</pre></div></figure>"' "$src" > "$tmp/flows"
jq -r '[.meta.key, .meta.title] | map(select(. != null and . != "")) | join(" ") | if . == "" then "Domain" else . end | @html' "$src" > "$tmp/title"

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
echo "built qa-docs/domains/${dom##*/}/visual/visual.html ($(wc -c < "$dir/visual.html" | tr -d ' ') bytes)"
