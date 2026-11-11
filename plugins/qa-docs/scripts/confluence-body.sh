#!/usr/bin/env bash
# Builds the body /qa-docs:export sends for one page of <domain>/confluence/: diagrams become the page's
# attachments (meta.json confluence.attachments, see confluence-attach.sh) and links between pages become
# Confluence page URLs (meta.json confluence.url / confluence.pages["<doc path>"].url).
# Usage: confluence-body.sh <qa-docs/domains/slug> <file.html> [--no-images]
#   --no-images  a diagram becomes a line with its title and its path on the qa-docs server
#                (no API token, or the upload failed)
# Writes <domain>/export/outgoing/<file.html> and prints its path; exit 1 with the reason when a diagram
# has no attachment or a linked page has no URL yet.
# shellcheck source=../hooks/scripts/lib.sh
. "$(dirname "$0")/../hooks/scripts/lib.sh"

[ "$#" -ge 2 ] || { echo "usage: confluence-body.sh <qa-docs/domains/slug> <file.html> [--no-images]" >&2; exit 2; }
noimg=0; [ "${3:-}" = "--no-images" ] && noimg=1
command -v jq >/dev/null 2>&1 || { echo "confluence-body: jq is required" >&2; exit 2; }

dom="$(qd_realpath "$(qd_abspath "$1")")"
base="$(qd_realpath "$(qd_domains)")"
case "$dom" in "$base"/*) ;; *) echo "confluence-body: '$1' is not a folder under $base" >&2; exit 2 ;; esac
rel="${dom#"$base"/}"; dom="$base/${rel%%/*}"; slug="${dom##*/}"
file="$2"
case "$file" in *[!a-z0-9.-]*|*..*) echo "confluence-body: bad page file '$file'" >&2; exit 2 ;; esac
meta="$dom/meta.json"; idx="$dom/confluence/pages.json"; page="$dom/confluence/$file"
[ -f "$page" ] && [ -f "$idx" ] && [ -f "$meta" ] || { echo "confluence-body: $file, pages.json or meta.json is missing in $dom" >&2; exit 2; }

# file -> URL, and file -> page id (for the attachment keys).
urls="$(jq -r --slurpfile m "$meta" '.pages[] | [.file,
  (if (.parent // "") == "" then ($m[0].confluence.url // "") else ($m[0].confluence.pages[.doc].url // "") end),
  (if (.parent // "") == "" then ($m[0].confluence.pageId // "") else ($m[0].confluence.pages[.doc].pageId // "") end)] | @tsv' "$idx")"
pid="$(awk -F'\t' -v f="$file" '$1 == f { print $3 }' <<<"$urls")"
atts="$(jq -r '.confluence.attachments // {} | to_entries[] | [.key, .value.fileId, .value.collection] | @tsv' "$meta")"

out="$dom/export/outgoing/$file"
mkdir -p "$dom/export/outgoing"
errs="$(mktemp "${TMPDIR:-/tmp}/qa-docs-body.XXXXXX")"
um="$errs.urls"; am="$errs.atts"
trap 'rm -f "$errs" "$um" "$am"' EXIT
# The maps go through files: awk -v does not take multi-line values everywhere.
printf '%s\n' "$urls" > "$um"; printf '%s\n' "$atts" > "$am"

awk -v um="$um" -v am="$am" -v pid="$pid" -v noimg="$noimg" -v slug="$slug" -v errs="$errs" '
  BEGIN {
    while ((getline l < um) > 0) { split(l, c, "\t"); url[c[1]] = c[2] }
    while ((getline l < am) > 0) { split(l, c, "\t"); fid[c[1]] = c[2]; coll[c[1]] = c[3] }
  }
  function attr(tag, a,   s) { s = tag; if (!match(s, a "=\"[^\"]*\"")) return ""; s = substr(s, RSTART + length(a) + 2, RLENGTH - length(a) - 3); return s }
  {
    line = $0; res = ""
    while (match(line, /<img[^>]*>/)) {
      tag = substr(line, RSTART, RLENGTH); pre = substr(line, 1, RSTART - 1); line = substr(line, RSTART + RLENGTH)
      name = attr(tag, "data-diagram"); alt = attr(tag, "alt"); key = pid "/" name
      if (noimg == 1)
        rep = "<p><strong>" alt "</strong>: <code>qa-docs/domains/" slug "/doc/diagrams/" name ".png</code></p>"
      else if (key in fid)
        rep = "<figure data-type=\"media-single\" data-layout=\"center\" data-width=\"80\" data-width-type=\"percentage\"><div data-type=\"media\" data-media-type=\"file\" data-id=\"" fid[key] "\" data-collection=\"" coll[key] "\" data-alt=\"" alt "\"></div></figure>"
      else { print "diagram \"" name "\" is not attached to page " pid ": run confluence-attach.sh first" >> errs; rep = tag }
      res = res pre rep
    }
    line = res line; res = ""
    while (match(line, /href="[a-z0-9.-]+\.html(#[^"]*)?"/)) {
      h = substr(line, RSTART + 6, RLENGTH - 7); pre = substr(line, 1, RSTART - 1); line = substr(line, RSTART + RLENGTH)
      f = h; sub(/#.*/, "", f)
      if (url[f] != "") rep = "href=\"" url[f] "\""
      else { print "link to " f ": that page has no Confluence URL in meta.json yet" >> errs; rep = "href=\"" h "\"" }
      res = res pre rep
    }
    print res line
  }' "$page" > "$out"

if [ -s "$errs" ]; then
  sort -u "$errs" | sed "s/^/$file: /"
  exit 1
fi
echo "$out"
