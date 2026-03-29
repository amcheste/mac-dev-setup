#!/usr/bin/env bash
# setup.sh — Bootstrap script for the developer environment.
# Installs Homebrew (if needed), taps this repo, runs brew bundle,
# symlinks dotfiles, and sets up credentials.
#
# Usage (fresh machine):
#   git clone https://github.com/amcheste/dev_env ~/Repos/amcheste/dev_env
#   cd ~/Repos/amcheste/dev_env && bash setup.sh
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ── Constants ────────────────────────────────────────────────────────────────
FAILED=1
SUCCESS=0

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Developer Environment Setup"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# ── Repos directory ──────────────────────────────────────────────────────────
if [[ ! -d "$HOME/Repos" ]]; then
    echo "▶ Creating ~/Repos..."
    mkdir -p "$HOME/Repos"
fi

# ── Homebrew ─────────────────────────────────────────────────────────────────
echo "▶ Checking Homebrew..."
if ! command -v brew &>/dev/null; then
    echo "  Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" \
        || { echo "ERROR: Failed to install Homebrew"; exit $FAILED; }

    # Add brew to PATH for Apple Silicon
    if [[ -f /opt/homebrew/bin/brew ]]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
        # shellcheck disable=SC2016  # single quotes intentional: writing literal string to file
        echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> "$HOME/.zprofile"
    fi
else
    echo "  Homebrew already installed ✓"
fi

# ── Tap this repo ────────────────────────────────────────────────────────────
echo ""
echo "▶ Tapping amcheste/dev-env..."
brew tap amcheste/dev-env https://github.com/amcheste/dev_env 2>/dev/null || true

# ── Brew Bundle ──────────────────────────────────────────────────────────────
echo ""
echo "▶ Installing packages (this may take a few minutes)..."
brew bundle --file="$REPO_DIR/Brewfile" --no-lock \
    || { echo "ERROR: brew bundle failed"; exit $FAILED; }

# ── Dotfiles ─────────────────────────────────────────────────────────────────
echo ""
echo "▶ Installing dotfiles..."
bash "$REPO_DIR/scripts/install-dotfiles.sh" \
    || { echo "ERROR: Failed to install dotfiles"; exit $FAILED; }

# ── Vim plugins ──────────────────────────────────────────────────────────────
echo ""
echo "▶ Installing Vim plugins..."
if [[ -f "$HOME/.vim/autoload/plug.vim" ]]; then
    vim +PlugInstall +qall 2>/dev/null && echo "  Vim plugins installed ✓" \
        || echo "  Warning: vim +PlugInstall had errors (plugins may still be installed)"
else
    echo "  vim-plug not found — skipping (run: install-dotfiles.sh first)"
fi

# ── Credentials ──────────────────────────────────────────────────────────────
echo ""
echo "▶ Setting up credentials..."
if [[ ! -f "$HOME/.secrets" ]] || ! grep -q 'ANTHROPIC_API_KEY="..*"' "$HOME/.secrets" 2>/dev/null; then
    bash "$REPO_DIR/scripts/setup-credentials.sh"
else
    echo "  ~/.secrets already configured ✓"
fi

# ── Done ─────────────────────────────────────────────────────────────────────
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Setup complete!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "  Restart your terminal, or run:  source ~/.zshrc"
echo ""
echo "  Optional next steps:"
echo "    brew install --HEAD amcheste/dev-env/dev-tools"
echo "    (installs the formula version with caveats and test support)"
echo ""

exit $SUCCESS
