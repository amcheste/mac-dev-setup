#!/usr/bin/env bash
# setup.sh — Bootstrap script for the developer environment.
# Installs Homebrew (if needed), taps this repo, runs brew bundle,
# symlinks dotfiles, and sets up credentials.
#
# Usage (fresh machine):
#   git clone https://github.com/amcheste/mac-dev-setup ~/Repos/amcheste/mac-dev-setup
#   cd ~/Repos/amcheste/mac-dev-setup && bash setup.sh
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
echo "▶ Tapping amcheste/mac-dev-setup..."
brew tap amcheste/mac-dev-setup https://github.com/amcheste/mac-dev-setup 2>/dev/null || true

# ── Brew Bundle ──────────────────────────────────────────────────────────────
echo ""
echo "▶ Installing packages (this may take a few minutes)..."
# BREWFILE env var allows alternate package lists (e.g. Brewfile.vm for VM tests)
BREWFILE_PATH="${BREWFILE:-$REPO_DIR/Brewfile}"
echo "  Using: $BREWFILE_PATH"
brew bundle --file="$BREWFILE_PATH" \
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
    vim --not-a-term -c "set nomore" +PlugInstall +qall >/dev/null 2>&1 && echo "  Vim plugins installed ✓" \
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

# ── Claude Code MCPs ─────────────────────────────────────────────────────────
echo ""
echo "▶ Configuring Claude Code MCP servers..."
if command -v claude &>/dev/null; then
    bash "$REPO_DIR/scripts/setup-mcps.sh"
else
    echo "  Claude Code not found — skipping MCP setup"
    echo "  Install Claude Code then run: bash scripts/setup-mcps.sh"
fi

# ── Done ─────────────────────────────────────────────────────────────────────
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Setup complete!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "  Restart your terminal, or run:  source ~/.zshrc"
echo ""
echo "  Claude Code is configured with:"
echo "    • CLAUDE.md  — your dev preferences and learned config"
echo "    • MCP servers — GitHub, filesystem, memory, PostgreSQL"
echo ""

exit $SUCCESS
