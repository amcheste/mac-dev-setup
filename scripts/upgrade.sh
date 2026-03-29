#!/usr/bin/env bash
# upgrade.sh — Update an existing developer environment installation.
# Run this after pulling changes to apply new packages and dotfile updates.
#
# Usage:
#   cd ~/Repos/amcheste/mac-dev-setup && bash scripts/upgrade.sh
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Developer Environment Upgrade"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# ── Pull latest changes ──────────────────────────────────────────────────────
echo "▶ Pulling latest changes..."
git -C "$REPO_DIR" pull --ff-only \
    || { echo "  Warning: could not fast-forward. Run 'git pull' manually."; }

# ── Update Homebrew and packages ─────────────────────────────────────────────
echo ""
echo "▶ Updating Homebrew..."
brew update

echo ""
echo "▶ Installing any new packages from Brewfile..."
brew bundle --file="$REPO_DIR/Brewfile"

echo ""
echo "▶ Upgrading installed packages..."
brew upgrade

# ── Refresh dotfile symlinks ─────────────────────────────────────────────────
echo ""
echo "▶ Refreshing dotfiles..."
bash "$REPO_DIR/scripts/install-dotfiles.sh"

# ── Update Vim plugins ───────────────────────────────────────────────────────
echo ""
echo "▶ Updating Vim plugins..."
if [[ -f "$HOME/.vim/autoload/plug.vim" ]]; then
    vim +PlugUpdate +qall 2>/dev/null \
        && echo "  Vim plugins updated ✓" \
        || echo "  Warning: vim +PlugUpdate had errors"
else
    echo "  vim-plug not found — skipping"
fi

# ── Sync MCP servers ─────────────────────────────────────────────────────────
# setup-mcps.sh is idempotent — skips servers already configured, adds any new
# ones added to the repo since the last upgrade.
echo ""
echo "▶ Syncing MCP servers..."
if command -v claude &>/dev/null; then
    bash "$REPO_DIR/scripts/setup-mcps.sh"
else
    echo "  Claude Code not found — skipping"
    echo "  Install Claude Code then run: bash scripts/setup-mcps.sh"
fi

# ── Done ─────────────────────────────────────────────────────────────────────
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Upgrade complete!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "  Restart your terminal or run:  source ~/.zshrc"
echo ""
