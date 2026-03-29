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
  shift
  if eval "$@" &>/dev/null; then
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
check "~/.zshrc is a symlink" "test -L ~/.zshrc"
check "~/.vimrc is a symlink" "test -L ~/.vimrc"

# ── Secrets ────────────────────────────────────────────────────────────────────

section "Secrets"
check "~/.secrets exists" "test -f ~/.secrets"
check "~/.secrets permissions are 0600" '[[ "$(stat -f "%Mp%Lp" ~/.secrets)" == "0600" ]]'

# ── Tools ──────────────────────────────────────────────────────────────────────

section "Tools"
TOOLS=(go kubectl helm terraform doctl jq gh vim fzf)
for tool in "${TOOLS[@]}"; do
  check "$tool is on PATH" "command -v $tool"
done

# ── Shell environment ──────────────────────────────────────────────────────────

section "Shell"
check "~/Repos directory exists" "test -d ~/Repos"
check "~/.zshrc is present" "test -f ~/.zshrc"

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
