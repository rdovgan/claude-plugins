#!/usr/bin/env bash
# Checks the Confluence pages of a domain (<domain>/confluence/) and builds their local preview.
# The pages are Confluence HTML body fragments, exactly what /qa-docs:export sends; pages.json gives the
# tree (file, title, the doc/ page it was made from, parent). Diagrams are written as
#   <img data-diagram="<name>" src="../doc/diagrams/<name>.png" alt="Title">
# and links between pages as <a href="<file>.html">; the export turns them into attachments and page URLs.
# Usage: confluence-pages.sh <qa-docs/domains/slug> [--check]
#   without --check also writes confluence/preview/<file>.html (full pages with styles and pictures)
#   --check only reports, and also reports pages older than doc/
# Prints one problem per line and "confluence: ..." at the end; exit 1 on any problem.
# shellcheck source=../hooks/scripts/lib.sh
. "$(dirname "$0")/../hooks/scripts/lib.sh"

[ "$#" -ge 1 ] || { echo "usage: confluence-pages.sh <qa-docs/domains/slug> [--check]" >&2; exit 2; }
check=0; [ "${2:-}" = "--check" ] && check=1
command -v jq >/dev/null 2>&1 || { echo "confluence-pages: jq is required" >&2; exit 2; }

dom="$(qd_realpath "$(qd_abspath "$1")")"
base="$(qd_realpath "$(qd_domains)")"
case "$dom" in "$base"/*) ;; *) echo "confluence-pages: '$1' is not a folder under $base" >&2; exit 2 ;; esac
rel="${dom#"$base"/}"; dom="$base/${rel%%/*}"
cf="$dom/confluence"
[ -d "$cf" ] || { echo "confluence: no confluence/ folder in $dom (domain-confluence builds it)"; exit 1; }

bad=0
problem() { echo "$1"; bad=$((bad + 1)); }

idx="$cf/pages.json"
if ! jq -e '.pages | type == "array" and length > 0' "$idx" >/dev/null 2>&1; then
  echo "confluence/pages.json is missing or has no \"pages\" list"
  echo "confluence: 0 pages, 1 problems"; exit 1
fi
files="$(jq -r '.pages[].file' "$idx")"
roots="$(jq '[.pages[] | select((.parent // "") == "")] | length' "$idx")"
[ "$roots" = 1 ] || problem "pages.json: exactly one page has no parent (the root); found $roots"
# "|" and not a tab: read collapses empty tab-separated fields.
while IFS='|' read -r f title parent doc; do
  case "$f" in *[!a-z0-9.-]*|-*|*..*|"") problem "pages.json: file name '$f': use lowercase latin letters, digits and '-' with .html"; continue ;; esac
  case "$f" in *.html) ;; *) problem "pages.json: '$f' is not an .html file"; continue ;; esac
  [ -f "$cf/$f" ] || problem "pages.json: '$f' does not exist in confluence/"
  [ -n "$title" ] || problem "pages.json: '$f' has no title"
  [ -z "$parent" ] || grep -qxF "$parent" <<<"$files" || problem "pages.json: parent '$parent' of '$f' is not in the list"
  [ -z "$doc" ] || [ -f "$dom/doc/$doc" ] || problem "pages.json: '$f' is made from doc/$doc, which does not exist"
done < <(jq -r '.pages[] | [.file, (.title // "" | gsub("[|]"; "/")), (.parent // ""), (.doc // "")] | join("|")' "$idx")
dups="$(jq -r '[.pages[].title] | group_by(.) | map(select(length > 1) | .[0]) | .[]' "$idx")"
[ -z "$dups" ] || problem "pages.json: titles used twice (Confluence needs unique titles in a space): $(tr '\n' ' ' <<<"$dups")"

n=0; pics=0
for page in "$cf"/*.html; do
  [ -f "$page" ] || continue
  f="${page##*/}"; n=$((n + 1))
  grep -qxF "$f" <<<"$files" || problem "$f: not listed in pages.json"
  grep -n '{{' "$page" | head -n 3 | while IFS= read -r l; do echo "$f:${l%%:*}: placeholder left: ${l#*:}"; done
  grep -q '{{' "$page" && bad=$((bad + 1))
  grep -qiE '<(!doctype|html|head|body)[[:space:]>]' "$page" && problem "$f: a body fragment only, without <html>, <head> or <body>"
  grep -qE '<(ac|ri):' "$page" && problem "$f: Confluence storage XML (<ac:...>, <ri:...>) renders as raw text; use the HTML patterns of the skill"
  grep -nE '^[[:space:]]*(#{1,6} |```|\|.*\|[[:space:]]*$)|\]\([^)]*\)|\*\*[^*]+\*\*' "$page" | head -n 3 | while IFS= read -r l; do
    echo "$f:${l%%:*}: markdown left in the HTML: ${l#*:}"
  done
  grep -qE '^[[:space:]]*(#{1,6} |```|\|.*\|[[:space:]]*$)|\]\([^)]*\)|\*\*[^*]+\*\*' "$page" && bad=$((bad + 1))
  # diagrams
  while IFS= read -r tag; do
    pics=$((pics + 1))
    name="$(sed -nE 's/.*data-diagram="([^"]*)".*/\1/p' <<<"$tag")"
    src="$(sed -nE 's/.*src="([^"]*)".*/\1/p' <<<"$tag")"
    alt="$(sed -nE 's/.*alt="([^"]*)".*/\1/p' <<<"$tag")"
    if [ -z "$name" ]; then problem "$f: <img src=\"$src\"> without data-diagram: pictures are diagrams of doc/diagrams/ only"; continue; fi
    [ "$src" = "../doc/diagrams/$name.png" ] || problem "$f: diagram '$name' must have src=\"../doc/diagrams/$name.png\""
    [ -n "$alt" ] || problem "$f: diagram '$name' has no alt text (the title shown with the picture)"
    [ -f "$dom/doc/diagrams/$name.png" ] || problem "$f: diagram '$name' has no PNG in doc/diagrams/: run render-diagrams.sh"
  done < <(grep -oE '<img[^>]*>' "$page")
  # links between pages
  while IFS= read -r href; do
    t="${href%%#*}"
    grep -qxF "$t" <<<"$files" || problem "$f: link to '$href', which is not a page in pages.json"
  done < <(grep -oE 'href="[^"]*"' "$page" | sed -E 's/^href="//; s/"$//' | grep -vE '^(https?:|mailto:|#)' | sort -u)
done

if [ "$check" = 1 ]; then
  newer="$(find "$dom/doc" -name '*.md' -newer "$idx" 2>/dev/null | sed "s#^$dom/##" | head -n 5 | tr '\n' ' ')"
  [ -z "$newer" ] || problem "confluence/ is older than $newer- rebuild it with domain-confluence (/qa-docs:confluence $(basename "$dom"))"
else
  pv="$cf/preview"
  mkdir -p "$pv"
  cp "$(dirname "$0")/../templates/confluence/preview.css" "$pv/style.css"
  rm -f "$pv"/*.html
  nav="$(jq -r '.pages[] | "<li" + (if (.parent // "") == "" then " class=\"root\"" else "" end) + "><a href=\"" + .file + "\">" + (.title | gsub("&"; "&amp;") | gsub("<"; "&lt;")) + "</a></li>"' "$idx")"
  while IFS=$'\t' read -r f title; do
    [ -f "$cf/$f" ] || continue
    {
      printf '<!doctype html>\n<html><head><meta charset="utf-8"><title>%s</title><link rel="stylesheet" href="style.css"></head>\n' "$title"
      printf '<body><nav><p>Preview of the Confluence pages, not the published version.</p><ul>\n%s\n</ul></nav>\n<main><h1>%s</h1>\n' "$nav" "$title"
      sed -E 's#src="\.\./doc/diagrams/#src="../../doc/diagrams/#g' "$cf/$f"
      printf '</main></body></html>\n'
    } > "$pv/$f"
  done < <(jq -r '.pages[] | [.file, .title] | @tsv' "$idx")
fi

echo "confluence: $n pages, $pics diagrams, $bad problems"
[ "$bad" -eq 0 ]
