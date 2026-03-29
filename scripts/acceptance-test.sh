#!/usr/bin/env bash
# Acceptance test suite. Runs INSIDE the Tart VM after setup.sh completes.
# Collects all failures before exiting — does not short-circuit on first error.

set -euo pipefail

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

# ── Homebrew ───────────────────────────────────────────────────────────────────

section "Homebrew"
check "brew is on PATH" "command -v brew"

# ── Dotfiles ───────────────────────────────────────────────────────────────────

section "Dotfiles"
check "$HOME/.zshrc is a symlink" "test -L $HOME/.zshrc"
check "$HOME/.vimrc is a symlink" "test -L $HOME/.vimrc"

# ── Secrets ────────────────────────────────────────────────────────────────────

section "Secrets"
check "$HOME/.secrets exists" "test -f $HOME/.secrets"
# shellcheck disable=SC2016
check "$HOME/.secrets permissions are 0600" \
  '[[ "$(stat -f \"%Mp%Lp\" '"$HOME"'/.secrets)" == "0600" ]]'

# ── Tools ──────────────────────────────────────────────────────────────────────

section "Tools"
TOOLS=(go kubectl helm terraform doctl jq gh vim fzf)
for tool in "${TOOLS[@]}"; do
  check "$tool is on PATH" "command -v $tool"
done

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
