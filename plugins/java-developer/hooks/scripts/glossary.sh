#!/usr/bin/env bash
# Team terminology (D-49), the same file in every plugin. Sourced by the hooks.
# A glossary is a markdown table: | Term | We say | Avoid |. "Avoid" lists wrong translations, comma separated;
# `*` in one stands for any letters, so a stem catches every case form ("нічн* цін*" -> "нічної ціни").
# Files, all read, later ones add to earlier ones:
#   1. the plugin's reference/glossary.md (common developer jargon),
#   2. the team's glossary.md in the workspace root (JAVA_TEAM_GLOSSARY overrides the path),
#   3. a project's or a plugin's own file passed by the hook (terms learned in sessions).

# Existing glossary files, one per line: gl_files <plugin root> <workspace> [more files...]
gl_files() {
  local root="$1" ws="$2" f
  shift 2
  for f in "$root/reference/glossary.md" "${JAVA_TEAM_GLOSSARY:-$ws/glossary.md}" "$@"; do
    [ -f "$f" ] && printf '%s\n' "$f"
  done | awk '!seen[$0]++'
}

# Table rows of the files as "term<TAB>we say<TAB>avoid", header and separator rows skipped.
gl_rows() {
  local f
  for f in "$@"; do
    awk -F'|' '/^\|/ && NF >= 4 {
        t = $2; s = $3; a = $4
        gsub(/^[ \t`]+|[ \t`]+$/, "", t); gsub(/^[ \t`]+|[ \t`]+$/, "", s); gsub(/^[ \t]+|[ \t]+$/, "", a)
        if (t == "" || t ~ /^-+$/ || tolower(t) == "term") next
        print t "\t" s "\t" a
      }' "$f"
  done
}

# Glossary files as an array (paths may have spaces): gl_load <plugin root> <workspace> [more files...] -> GL_FILES
gl_load() {
  GL_FILES=()
  local f
  while IFS= read -r f; do GL_FILES+=("$f"); done < <(gl_files "$@")
}

# The rule and the terms, for the session context:
# gl_context <plugin name> <file to add learned terms to> <plugin root> <workspace> [more files...]
gl_context() {
  local name="$1" learn="$2" rows
  shift 2
  gl_load "$@"
  set -- ${GL_FILES[@]+"${GL_FILES[@]}"}
  echo "$name: TERMS. When you write in Ukrainian (or any language but English), write the way the team's developers talk: keep in English, in Latin letters, the names from the code, Jira and Confluence (entities, statuses, fields, processes, partners, settings) and common developer jargon (deploy, release, merge, PR, branch, hotfix, rollback, build, job, endpoint, mapping, ...). Never translate them word for word; fit them into the sentence (\"задеплоїти\", \"PR змерджено\", \"процес unbundling\", \"nightly rate для цієї дати\"). When unsure, keep the English term. The glossary below is binding: use the 'we say' form, never an 'avoid' one. When the user corrects a term, add a row to $learn (create it with the header '| Term | We say | Avoid |' if missing) in the same turn."
  rows="$(gl_rows "$@" | head -n 200)"
  [ -n "$rows" ] || return 0
  echo "$name: glossary (term -> we say; avoid):"
  printf '%s\n' "$rows" | awk -F'\t' '{ printf "  %s -> %s%s\n", $1, ($2 == "" ? $1 : $2), ($3 == "" ? "" : "; avoid: " $3) }'
}

# Wrong translations found in report files, one line each: "<file>: '<found>' - write '<we say>'".
# gl_check <files to check...> -- <plugin root> <workspace> [more glossary files...]
gl_check() {
  local checked=() rest=() seen_sep=0 a pattern loc found
  for a in "$@"; do
    if [ "$a" = "--" ]; then seen_sep=1; continue; fi
    if [ "$seen_sep" = 0 ]; then checked+=("$a"); else rest+=("$a"); fi
  done
  [ "${#checked[@]}" -gt 0 ] && [ "${#rest[@]}" -ge 2 ] || return 0
  gl_load "${rest[@]}"
  local glossaries=(${GL_FILES[@]+"${GL_FILES[@]}"})
  [ "${#glossaries[@]}" -gt 0 ] || return 0
  loc="$(locale -a 2>/dev/null | grep -ixE 'c\.utf-?8|en_us\.utf-?8' | head -n1)"
  gl_rows "${glossaries[@]}" | while IFS=$'\t' read -r term say avoid; do
    [ -n "$avoid" ] || continue
    printf '%s\n' "$avoid" | tr ',' '\n' | while IFS= read -r a; do
      a="$(printf '%s' "$a" | sed -E 's/^[[:space:]]+|[[:space:]]+$//g')"
      [ -n "$a" ] || continue
      # Escape regex characters, then turn * into "any letters".
      pattern="$(printf '%s' "$a" | sed -E 's/[][\.^$+?(){}|/]/\\&/g; s/\*/[[:alpha:]]*/g')"
      for f in "${checked[@]}"; do
        [ -f "$f" ] || continue
        found="$(LC_ALL="${loc:-en_US.UTF-8}" grep -ioE -- "$pattern" "$f" 2>/dev/null | head -n1)"
        [ -n "$found" ] && printf "%s: '%s' - write '%s'\n" "$f" "$found" "${say:-$term}"
      done
    done
  done
  return 0
}
