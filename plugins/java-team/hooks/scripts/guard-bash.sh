#!/usr/bin/env bash
# PreToolUse Bash: блокує небезпечні команди (код 2, причина в stderr).
# shellcheck source=lib.sh
. "$(dirname "$0")/lib.sh"
jt_require_jq

cmd="$(jq -r '.tool_input.command // empty' <<<"$(cat)")"
[ -n "$cmd" ] || exit 0

block() {
  echo "java-team: команду заблоковано: $1 Безпечна альтернатива: $2" >&2
  exit 2
}

current_branch="$(jt_branch)"

# Розбиваємо ланцюжки команд на окремі сегменти.
while IFS= read -r seg; do
  [ -n "${seg// /}" ] || continue
  # shellcheck disable=SC2086
  read -r -a t <<<"$(printf '%s' "$seg" | tr -d "'\"")"
  [ "${#t[@]}" -gt 0 ] || continue
  s=" ${t[*]} "

  # rm -rf поза target/
  if [[ "$s" =~ [[:space:]]rm[[:space:]] ]] && [[ "$s" =~ [[:space:]](-[a-zA-Z]*[rR][a-zA-Z]*|--recursive)[[:space:]] ]]; then
    for a in "${t[@]}"; do
      case "$a" in -*|rm|sudo) continue ;; esac
      if [[ "$a" == *..* ]] || ! [[ "$a" =~ ^(\./)?([^[:space:]]*/)?target(/.*)?$ ]]; then
        block "рекурсивне видалення '$a' поза target/." "видаляй лише target/ (mvn clean) або конкретні файли."
      fi
    done
  fi

  # git push
  if [[ "$s" =~ [[:space:]]git[[:space:]]+push[[:space:]] ]]; then
    for a in "${t[@]}"; do
      case "$a" in
        --force|--force-with-lease*|--force-if-includes|-f|-[a-zA-Z]*f*)
          [[ "$a" == -* ]] && block "git push з --force/-f." "звичайний git push у власну гілку; переписування історії узгодь з техлідом." ;;
      esac
    done
    if [[ "$s" =~ [[:space:]](main|master|HEAD:main|HEAD:master|:main|:master|refs/heads/main|refs/heads/master)[[:space:]] ]]; then
      block "git push у main/master." "запуш feature-гілку і створи PR."
    fi
    if [ "$current_branch" = "main" ] || [ "$current_branch" = "master" ]; then
      block "git push з гілки $current_branch." "створи гілку (git checkout -b) і запуш її."
    fi
  fi

  [[ "$s" =~ [[:space:]]git[[:space:]]+reset[[:space:]].*--hard ]] && \
    block "git reset --hard знищує незакомічені зміни." "git stash або git restore для конкретних файлів."

  if [[ "$s" =~ [[:space:]]git[[:space:]]+clean[[:space:]] ]] && [[ "$s" =~ [[:space:]]-[a-zA-Z]*f[a-zA-Z]*[[:space:]] ]] && [[ "$s" =~ [[:space:]]-[a-zA-Z]*x[a-zA-Z]* ]]; then
    block "git clean -fdx видаляє ігноровані файли (у т.ч. локальні налаштування)." "git clean -n для перегляду або mvn clean."
  fi

  # Читання чутливих файлів
  if [[ "$s" =~ [[:space:]](cat|less|more|head|tail|grep|egrep|fgrep|rg|sed|awk|bat|xxd|strings|base64|cp|scp|source|\.)[[:space:]] ]]; then
    for a in "${t[@]}"; do
      a="${a#<}"
      case "$a" in -*) continue ;; esac
      if jt_is_sensitive "$a"; then
        block "читання чутливого файлу '$a'." "працюй із application-local*/application-test* або попроси розробника надати значення."
      fi
    done
  fi

  # Передача файлів назовні
  if [[ "$s" =~ [[:space:]](curl|wget)[[:space:]] ]] && \
     [[ "$s" =~ ([[:space:]](-d|--data|--data-binary|--data-raw|--data-urlencode|-F|--form)[[:space:]=]*[^[:space:]]*@|--upload-file|--post-file|[[:space:]]-T[[:space:]]) ]]; then
    block "curl/wget передає файли на зовнішню адресу." "завантажуй дані лише в GET-режимі; відправлення файлів роби вручну."
  fi

  # Maven: публікація, реліз, міграції
  if [[ "$s" =~ [[:space:]](mvn|\./mvnw|mvnw)[[:space:]] ]]; then
    [[ "$s" =~ [[:space:]](deploy|[a-z-]+:deploy)[[:space:]] ]] && block "mvn deploy публікує артефакти." "використовуй mvn verify."
    [[ "$s" =~ [[:space:]]release: ]] && block "mvn release:* змінює версії й публікує." "реліз виконує CI/техлід."
    if [[ "$s" =~ (flyway:migrate|liquibase:update) ]] && ! [[ "$s" =~ [[:space:]]-P[[:space:]]?[^[:space:]]*(test|local) ]]; then
      block "міграції БД з не-тестовим профілем." "додай тестовий профіль (-Ptest) або застосовуй міграції через CI."
    fi
  fi
done < <(printf '%s\n' "$cmd" | sed -e 's/&&/\n/g' -e 's/||/\n/g' -e 's/[;|&]/\n/g')

exit 0
