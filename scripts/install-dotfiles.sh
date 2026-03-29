#!/usr/bin/env bash
# install-dotfiles.sh
# Symlinks dotfiles from this repo (or brew pkgshare) into $HOME.
# Existing files are backed up with a .bak extension.
set -euo pipefail

# ── Locate dotfiles ──────────────────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(dirname "$SCRIPT_DIR")"
DOTFILES_DIR="$REPO_DIR/dotfiles"

# If running after `brew install dev-tools`, dotfiles live in pkgshare
if command -v brew &>/dev/null; then
    BREW_DOTFILES="$(brew --prefix)/share/dev-tools/dotfiles"
    if [[ -d "$BREW_DOTFILES" ]]; then
        DOTFILES_DIR="$BREW_DOTFILES"
    fi
fi

if [[ ! -d "$DOTFILES_DIR" ]]; then
    echo "ERROR: dotfiles directory not found at $DOTFILES_DIR"
    exit 1
fi

echo "Installing dotfiles from: $DOTFILES_DIR"
echo ""

# ── Helper ───────────────────────────────────────────────────────────────────
backup_and_link() {
    local source="$1"
    local target="$2"

    if [[ -e "$target" && ! -L "$target" ]]; then
        echo "  Backing up   $target  →  ${target}.bak"
        mv "$target" "${target}.bak"
    elif [[ -L "$target" ]]; then
        rm "$target"
    fi

    ln -sf "$source" "$target"
    echo "  Linked       $target  →  $source"
}

# ── Symlink dotfiles ─────────────────────────────────────────────────────────
backup_and_link "$DOTFILES_DIR/zshrc"  "$HOME/.zshrc"
backup_and_link "$DOTFILES_DIR/vimrc"  "$HOME/.vimrc"

# ── Secrets template (only if ~/.secrets doesn't exist) ─────────────────────
if [[ ! -f "$HOME/.secrets" ]]; then
    echo ""
    echo "  Creating     ~/.secrets  (from template — fill in your values)"
    cp "$DOTFILES_DIR/secrets.template" "$HOME/.secrets"
    chmod 600 "$HOME/.secrets"
fi

# ── vim-plug bootstrap ───────────────────────────────────────────────────────
VIM_PLUG="$HOME/.vim/autoload/plug.vim"
if [[ ! -f "$VIM_PLUG" ]]; then
    echo ""
    echo "  Installing vim-plug..."
    curl -fLo "$VIM_PLUG" --create-dirs \
        https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
    echo "  vim-plug installed ✓"
fi

# ── Claude Code skills ────────────────────────────────────────────────────────
SKILLS_SRC_DIR="$REPO_DIR/claude-skills"
SKILLS_DEST_DIR="$HOME/.claude/skills"

if [[ -d "$SKILLS_SRC_DIR" ]]; then
    echo ""
    mkdir -p "$SKILLS_DEST_DIR"
    for skill_dir in "$SKILLS_SRC_DIR"/*/; do
        skill_name="$(basename "$skill_dir")"
        dest="$SKILLS_DEST_DIR/$skill_name"
        if [[ -L "$dest" ]]; then
            rm "$dest"
        elif [[ -d "$dest" ]]; then
            mv "$dest" "${dest}.bak"
            echo "  Backing up   $dest  →  ${dest}.bak"
        fi
        ln -sf "$skill_dir" "$dest"
        echo "  Linked       $dest  →  $skill_dir"
    done
    echo "  Claude Code skills installed ✓  (invoke with /publish-release)"
fi

echo ""
echo "Done! Next steps:"
echo "  1. vim +PlugInstall +qall     — install Vim plugins"
echo "  2. setup-credentials.sh       — fill in ~/.secrets with API keys"
echo "  3. source ~/.zshrc            — reload shell (or open a new terminal)"
