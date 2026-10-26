#!/usr/bin/env bash
# Renders the mermaid diagrams of a domain document to PNG, kept on the server next to their source.
# Every ```mermaid block in <domain>/doc/**/*.md must be preceded by its picture link,
#   ![Title](<relative path>/diagrams/<name>.png)
# The block is saved as doc/diagrams/<name>.mmd and rendered to doc/diagrams/<name>.png with mermaid-cli
# (QA_DOCS_MMDC, default `mmdc`) when the source changed. A syntax error is reported with mmdc's message.
# Usage: render-diagrams.sh <qa-docs/domains/slug> [--check]
#   --check renders nothing: reports blocks without a picture link, missing or outdated PNGs
#   (a missing PNG is not reported when mermaid-cli is not installed: nothing could render it).
# Prints one problem per line and "diagrams: ..." at the end; exit 1 on any problem.
# shellcheck source=../hooks/scripts/lib.sh
. "$(dirname "$0")/../hooks/scripts/lib.sh"

[ "$#" -ge 1 ] || { echo "usage: render-diagrams.sh <qa-docs/domains/slug> [--check]" >&2; exit 2; }
check=0; [ "${2:-}" = "--check" ] && check=1

dom="$(qd_realpath "$(qd_abspath "$1")")"
base="$(qd_realpath "$(qd_domains)")"
case "$dom" in "$base"/*) ;; *) echo "render-diagrams: '$1' is not a folder under $base" >&2; exit 2 ;; esac
rel="${dom#"$base"/}"; dom="$base/${rel%%/*}"
doc="$dom/doc"
[ -d "$doc" ] || { echo "diagrams: 0 (no doc/ folder in $dom)"; exit 0; }
out="$doc/diagrams"

mmdc="$(qd_conf QA_DOCS_MMDC mmdc)"
have_mmdc=0; command -v "$mmdc" >/dev/null 2>&1 && have_mmdc=1
pconf="$(dirname "$0")/puppeteer.json"
# A system Chrome/Chromium shared by all users, instead of the one puppeteer downloads per user.
chrome="$(qd_conf QA_DOCS_CHROME)"
[ -n "$chrome" ] && export PUPPETEER_EXECUTABLE_PATH="$chrome"

tmp="$(mktemp -d "${TMPDIR:-/tmp}/qa-docs-mmd.XXXXXX")"
trap 'rm -rf "$tmp"' EXIT

n=0; rendered=0; bad=0; names=" "
problem() { echo "$1"; bad=$((bad + 1)); }

# Blocks of one page as records: "@@ <line> <picture path or ->", the block lines, "@@end".
blocks() {
  awk '
    /^```mermaid[[:space:]]*$/ && !inb { inb = 1; printf "@@ %d %s\n", NR, (pic != "" ? pic : "-"); next }
    inb && /^```[[:space:]]*$/ { inb = 0; print "@@end"; pic = ""; next }
    inb { print; next }
    /^[[:space:]]*$/ { next }
    { pic = ""
      if (match($0, /^!\[[^]]*\]\([^) ]+\.png\)[[:space:]]*$/)) { s = $0; sub(/^!\[[^]]*\]\(/, "", s); sub(/\).*$/, "", s); pic = s } }
  ' "$1"
}

while IFS= read -r page; do
  rel="${page#"$dom"/}"
  cur=""; line=""; bodyf=""
  while IFS= read -r l; do
    if [ -z "$cur" ] && [ "${l:0:3}" = "@@ " ]; then
      # shellcheck disable=SC2086
      set -- $l; line="$2"; cur="$3"; bodyf="$tmp/body"; : > "$bodyf"; continue
    fi
    if [ -n "$cur" ] && [ "$l" = "@@end" ]; then
      n=$((n + 1))
      if [ "$cur" = "-" ]; then
        problem "$rel:$line: mermaid block without a picture link on the line before it: add ![Title](diagrams/<name>.png) (path relative to this page)"
      else
        name="$(basename "$cur" .png)"
        target="$(qd_abspath "$cur" "$(dirname "$page")")"
        if [ "$target" != "$out/$name.png" ]; then
          problem "$rel:$line: picture '$cur' must point to doc/diagrams/$name.png relative to this page"
        elif ! printf '%s' "$name" | grep -qE '^[a-z0-9][a-z0-9-]*$'; then
          problem "$rel:$line: diagram name '$name': use lowercase latin letters, digits and '-'"
        elif [[ "$names" == *" $name "* ]]; then
          problem "$rel:$line: diagram name '$name' is used twice; names are unique within the domain"
        else
          names="$names$name "
          if [ "$check" = 1 ]; then
            if [ ! -f "$out/$name.mmd" ] || ! cmp -s "$bodyf" "$out/$name.mmd"; then
              problem "$rel:$line: diagram '$name' changed since it was rendered: run render-diagrams.sh"
            elif [ ! -f "$out/$name.png" ] && [ "$have_mmdc" = 1 ]; then
              problem "$rel:$line: diagram '$name' has no PNG: run render-diagrams.sh"
            fi
          else
            mkdir -p "$out"
            cmp -s "$bodyf" "$out/$name.mmd" 2>/dev/null || cp "$bodyf" "$out/$name.mmd"
            if [ ! -f "$out/$name.png" ] || [ "$out/$name.mmd" -nt "$out/$name.png" ]; then
              if [ "$have_mmdc" = 0 ]; then
                problem "$rel:$line: '$name.png' not rendered: mermaid-cli ($mmdc) is not installed; the admin installs it (server/README.md). The mermaid code is kept"
              elif err="$("$mmdc" -q -i "$out/$name.mmd" -o "$out/$name.png" -b white -s 2 -p "$pconf" 2>&1)"; then
                rendered=$((rendered + 1))
              else
                rm -f "$out/$name.png"
                problem "$rel:$line: diagram '$name' does not render: $(printf '%s' "$err" | grep -v '^[[:space:]]*at ' | head -n 4 | tr '\n' ' ')"
              fi
            fi
          fi
        fi
      fi
      cur=""; continue
    fi
    [ -n "$cur" ] && printf '%s\n' "$l" >> "$bodyf"
  done < <(blocks "$page")
done < <(find "$doc" -name '*.md' -not -path '*/diagrams/*' | sort)

echo "diagrams: $n found, $rendered rendered, $bad problems"
[ "$bad" -eq 0 ]
