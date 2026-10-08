#!/usr/bin/env bash
# One-command setup of the java-developer plugin on a developer machine.
#   ./install.sh          interactive
#   ./install.sh --yes    no questions (does not touch shell rc files)
# Safe to re-run. Never reads or prints secrets.
set -u

MARKETPLACE_URL="${MARKETPLACE_URL:-git@github.com:rdovgan/claude-plugins.git}"   # override for a fork or a private mirror
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MARKETPLACE_NAME="team-plugins"
PLUGIN="${PLUGIN:-java-developer}"   # PLUGIN=java-analyst ./install.sh for the analysis-only plugin
YES=0; [ "${1:-}" = "--yes" ] && YES=1

ok()   { printf '  [ok]   %s\n' "$1"; }
warn() { printf '  [warn] %s\n' "$1"; }
fail() { printf '  [FAIL] %s\n' "$1"; }
ask() { # ask "question" -> 0 for yes
  [ "$YES" = 1 ] && return 1
  [ -r /dev/tty ] || return 1
  local a; printf '%s [y/N] ' "$1" >/dev/tty; read -r a </dev/tty; [[ "$a" =~ ^[Yy] ]]
}

echo "$PLUGIN setup"
echo
echo "1. Tools"
missing=0
if command -v claude >/dev/null 2>&1; then ok "claude"; else fail "claude CLI not found: https://docs.claude.com/en/docs/claude-code"; missing=1; fi
for t in git jq mvn; do
  if command -v "$t" >/dev/null 2>&1; then ok "$t"; else
    if [ "$t" = jq ]; then warn "jq missing: hooks will only warn instead of protecting (brew install jq / apt install jq)"
    else fail "$t missing (mvn: brew install maven, or use the project's ./mvnw)"; [ "$t" = git ] && missing=1; fi
  fi
done
if command -v java >/dev/null 2>&1; then
  ok "java: $(java -version 2>&1 | head -n1)"
  warn "each repository needs the JDK its pom.xml targets; switch with your JDK manager if needed"
else warn "java not found on PATH"; fi
[ "$missing" = 1 ] && { echo; echo "Install the missing tools and run this script again."; exit 1; }

echo
echo "2. Marketplace and plugin"
run() { "$@" 2>&1 | sed 's/^/       /'; return "${PIPESTATUS[0]}"; }
if run claude plugin marketplace add "$MARKETPLACE_URL"; then
  ok "marketplace added from $MARKETPLACE_URL"
elif [ -f "$HERE/.claude-plugin/marketplace.json" ] && run claude plugin marketplace add "$HERE"; then
  warn "SSH clone failed, added this local clone instead ($HERE). Update with 'git pull' here, then 'claude plugin marketplace update $MARKETPLACE_NAME'."
  warn "To use the remote: add your SSH key to GitHub (Settings -> SSH keys), check 'ssh -T git@github.com', re-run."
else
  fail "cannot add the marketplace from $MARKETPLACE_URL. Check access: for SSH, 'ssh -T git@github.com' must greet you. Then re-run."
  exit 1
fi
run claude plugin marketplace update "$MARKETPLACE_NAME" >/dev/null
if run claude plugin install "$PLUGIN@$MARKETPLACE_NAME"; then ok "plugin $PLUGIN installed"; else fail "plugin install failed, see the message above"; exit 1; fi

echo
echo "3. Environment variables (values are never printed)"
rc="$HOME/.zshrc"; [ -n "${BASH_VERSION:-}" ] && [ "${SHELL##*/}" = bash ] && rc="$HOME/.bashrc"
if [ "$PLUGIN" != "java-analyst" ]; then   # the vault is used by session-summary only
  if [ -n "${JAVA_TEAM_VAULT:-}" ]; then ok "JAVA_TEAM_VAULT is set"; else
    warn "JAVA_TEAM_VAULT not set (Obsidian vault for session-summary; default ~/Claude Vault)"
    if ask "Add 'export JAVA_TEAM_VAULT=\"\$HOME/Claude Vault\"' to $rc?"; then
      printf '\nexport JAVA_TEAM_VAULT="$HOME/Claude Vault"\n' >> "$rc"; ok "added to $rc"
    fi
  fi
fi
db_missing=""
for v in JAVA_TEAM_DB_URL JAVA_TEAM_DB_USER JAVA_TEAM_DB_PASSWORD; do [ -n "${!v:-}" ] || db_missing="$db_missing $v"; done
if [ -z "$db_missing" ]; then ok "DB variables are set"; else
  warn "DB access is optional; not set:$db_missing"
  echo "       Set them yourself (read-only DEMO user; never commit them), see docs/install.md"
fi

echo
echo "Done. Next steps:"
echo "  1. cd into a project and run: claude"
if [ "$PLUGIN" = "java-analyst" ]; then
  echo "  2. type: /java-analyst:help, then /java-analyst:analyze <task>"
  echo "  3. in Claude Code run /mcp and complete OAuth for jira (read-only)"
else
  echo "  2. type: /java-developer:onboarding   (a guided tour, about 5 minutes)"
fi
