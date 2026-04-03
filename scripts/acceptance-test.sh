#!/usr/bin/env bash
# Acceptance test suite. Run after setup.sh completes on any macOS machine.
# Works both locally and on GitHub-hosted macOS runners (no VM required).
# Collects all failures before exiting — does not short-circuit on first error.

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Ensure Homebrew tools are on PATH — this script runs via non-login bash
# so .zprofile is never sourced.
export PATH="/opt/homebrew/bin:/opt/homebrew/sbin:$PATH"

PASS=0
FAIL=0
FAILURES=()

# ── Helpers ────────────────────────────────────────────────────────────────────

section() {
  echo ""
  echo "━━━ $1 ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
}

check() {
  local desc="$1"
  local cmd="$2"
  if bash -c "$cmd" &>/dev/null; then
    echo "  ✓ $desc"
    PASS=$((PASS + 1))
  else
    echo "  ✗ $desc"
    FAIL=$((FAIL + 1))
    FAILURES+=("$desc")
  fi
}

# ── Preflight ──────────────────────────────────────────────────────────────────

section "Preflight"
check "running on macOS" "test \"\$(uname)\" = Darwin"
check "current user is in admin group" "id -Gn | tr ' ' '\n' | grep -q '^admin$'"
check "Homebrew prefix is writable" "test -w \"\$(brew --prefix)\""

# ── Homebrew ───────────────────────────────────────────────────────────────────

section "Homebrew"
check "brew is on PATH" "command -v brew"
check "no deprecated formulae in Brewfile" \
  "! brew bundle check --file=\"$REPO_DIR/Brewfile\" 2>&1 | grep -qi deprecated"

# ── Dotfiles ───────────────────────────────────────────────────────────────────

section "Dotfiles"
check "$HOME/.zshrc is a symlink" "test -L $HOME/.zshrc"
check "$HOME/.vimrc is a symlink" "test -L $HOME/.vimrc"

# ── Secrets ────────────────────────────────────────────────────────────────────

section "Secrets"
check "$HOME/.secrets exists" "test -f $HOME/.secrets"
check "$HOME/.secrets permissions are 0600" \
  "find $HOME/.secrets -maxdepth 0 -perm 0600 | grep -q ."

# ── Tools ──────────────────────────────────────────────────────────────────────

section "Tools"
TOOLS=(go kubectl helm terraform doctl jq gh vim fzf)
for tool in "${TOOLS[@]}"; do
  check "$tool is on PATH" "command -v $tool"
done

# ── Claude Skills ──────────────────────────────────────────────────────────────

section "Claude Skills"
check "publish-release skill is linked" "test -L $HOME/.claude/skills/publish-release"
check "setup-repo skill is linked"      "test -L $HOME/.claude/skills/setup-repo"
check "create-repo skill is linked"     "test -L $HOME/.claude/skills/create-repo"

# ── Shell environment ──────────────────────────────────────────────────────────

section "Shell"
check "$HOME/Repos directory exists" "test -d $HOME/Repos"
check "$HOME/.zshrc is present" "test -f $HOME/.zshrc"

# ── Summary ────────────────────────────────────────────────────────────────────

echo ""
echo "━━━ Results ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Passed: $PASS"
echo "  Failed: $FAIL"

if [[ $FAIL -gt 0 ]]; then
  echo ""
  echo "Failures:"
  for f in "${FAILURES[@]}"; do
    echo "  - $f"
  done
  exit 1
fi

echo ""
echo "✓ All checks passed."
